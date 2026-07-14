import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http_wrap/http_wrap.dart';
import 'package:http_wrap_example/main.dart';

class ItemDownloadView extends StatefulWidget {
  const ItemDownloadView({super.key});

  @override
  State<ItemDownloadView> createState() => _ItemDownloadViewState();
}

const dummyVideo =
    """https://static.videezy.com/system/resources/previews/000/004/690/original/Squared_-_Slideshow.mp4""";

class _ItemDownloadViewState extends State<ItemDownloadView> {
  final _urlCtrl = TextEditingController(
    text: dummyVideo,
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

  Future<void> _cancelDownload() async {
    await _downloadController?.cancel();
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Download canceled and cleaned up';
    });
  }

  Future<void> _startDownload() async {
    final url = _urlCtrl.text.trim();

    if (url.isEmpty) {
      setState(() => _statusMessage = 'URL is required');
      return;
    }

    final saveDirectory = "/storage/emulated/0/Download/";

    _downloadSubscription?.cancel();

    final controller = httpWrapPlugin.download(
      url: url,
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
        } else if (info.state == .canceled) {
          _statusMessage = 'Download canceled';
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
                ElevatedButton(
                  onPressed: _cancelDownload,
                  child: const Text('Cancel'),
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
