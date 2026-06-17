import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http_wrap/download_controller.dart';
import 'package:http_wrap/download_state.dart';
import 'package:http_wrap_example/main.dart';
import 'package:permission_handler/permission_handler.dart';

class ItemDownloadView extends StatefulWidget {
  const ItemDownloadView({super.key});

  @override
  State<ItemDownloadView> createState() => _ItemDownloadViewState();
}

const vscode =
    """https://vscode.download.prss.microsoft.com/"""
    """dbazure/download/stable/6928394f91b684055b873eecb8bc281365131f1c/"""
    """VSCodeUserSetup-x64-1.124.2.exe""";

const randomImage =
    """https://imgs.search.brave.com/EGb6Sk84WbBuotAQg87x_n4_zs"""
    """0-nWLi_GbmEXygS6c/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9zdGF0/aWMudmVjdGVlenku/Y29t"""
    """L3N5c3RlbS9y/ZXNvdXJjZXMvdGh1/bWJuYWlscy8wNTMv/MTkzLzU4OS9zbWFs/bC9hLXdvbWFuLX"""
    """Rh/a2luZy1hLXBpY3R1/cmUtd2l0aC1hLWNh/bWVyYS1mcmVlLXBo/b3RvLmpwZw""";

class _ItemDownloadViewState extends State<ItemDownloadView> {
  final _urlCtrl = TextEditingController(
    text: randomImage,
  );

  DownloadController? _downloadController;
  StreamSubscription<DownloadInfo>? _downloadSubscription;

  DownloadInfo _downloadInfo = const DownloadInfo();
  String _statusMessage = 'Paste a URL and start download';

  void _pauseDownload() {
    _downloadController?.pause();
    setState(() => _statusMessage = 'Download paused');
  }

  void _resumeDownload() {
    _downloadController?.resume();
    setState(() => _statusMessage = 'Download resumed');
  }

  Future<void> _startDownload() async {
    final url = _urlCtrl.text.trim();

    if (url.isEmpty) {
      setState(() => _statusMessage = 'URL is required');
      return;
    }

    final saveDirectory = "/storage/emulated/0/Download/";
    // if (saveDirectory == null) return;

    _downloadSubscription?.cancel();

    final controller = httpWrapPlugin.download(
      url: url,
      // saveDirectory: saveDirectory..path,
      saveDirectory: saveDirectory,
    );

    _downloadController = controller;
    _downloadInfo = const DownloadInfo(
      state: .notStarted,
      progress: 0,
    );
    _statusMessage = 'Download started';

    _downloadSubscription = controller.progressStream.listen((info) {
      setState(() {
        _downloadInfo = info;

        if (info.state == .downloading) {
          _statusMessage = 'Downloading...';
        } else if (info.state == .completed) {
          _statusMessage = 'Download completed';
        } else if (info.state == .failed) {
          _statusMessage = 'Download failed';
        }
      });
    });

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    Permission.manageExternalStorage.request();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _downloadSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_downloadInfo.progress ?? 0).clamp(0, 100);

    return Center(
      child: SingleChildScrollView(
        padding: const .all(12),
        child: Column(
          spacing: 12,
          children: [
            const Text('Paste a download URL and manage the download'),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(labelText: 'Download URL'),
            ),
            ElevatedButton(
              onPressed: _startDownload,
              child: const Text('Start Download'),
            ),
            Row(
              spacing: 8,
              mainAxisAlignment: .center,
              children: [
                ElevatedButton(
                  onPressed: _pauseDownload,
                  child: const Text('Pause'),
                ),
                ElevatedButton(
                  onPressed: _resumeDownload,
                  child: const Text('Resume'),
                ),
              ],
            ),
            LinearProgressIndicator(value: progress / 100),
            Text('Progress: ${progress.toStringAsFixed(1)}%'),
            Text('State: ${_downloadInfo.state.name}'),
            Text('Can Resume: ${_downloadInfo.canResume ?? false}'),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}
