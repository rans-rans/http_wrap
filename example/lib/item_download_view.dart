import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http_wrap/http_wrap.dart';
import 'package:http_wrap_example/main.dart';
import 'package:permission_handler/permission_handler.dart';

class ItemDownloadView extends StatefulWidget {
  const ItemDownloadView({super.key});

  @override
  State<ItemDownloadView> createState() => _ItemDownloadViewState();
}

const rickRoll =
    """https://nsf-m4c-one-fr-07.sf-converter.com/prod-new/download/"""
    """eyJtZWRpYUlkIjoiZFF3NHc5V2dYY1EiLCJ0aXRsZSI6IlJpY2sgQXN0bGV5IC0gTmV2ZXIgR29ubmEg"""
    """R2l2ZSBZb3UgVXAgKE9mZmljaWFsIFZpZGVvKSAoNEsgUmVtYXN0ZXIpIiwiZm9ybWF0IjoibXA0I"""
    """iwicXVhbGl0eSI6IjcyMCIsInRpbWVzdGFtcCI6MTc4MTc4OTEzMn0.8d5dcd25257c5f59852cf409a26b21a4""";

class _ItemDownloadViewState extends State<ItemDownloadView> {
  final _urlCtrl = TextEditingController(
    text: rickRoll,
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
