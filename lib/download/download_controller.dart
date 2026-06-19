import 'dart:async';

import 'package:http_wrap/download/download_state.dart';
import 'package:http_wrap/download/downloader.dart';

/// Controller for managing file downloads, providing methods to pause and resume downloads,
/// as well as a stream to track download progress and state.
/// The [DownloadController] allows you to control the download process and receive updates on the download status through the [progressStream].
/// The [progressStream] emits [DownloadInfo] objects that contain the current state of the download, the progress percentage, and whether the server supports resumable downloads.
/// Example usage:
/// ```dart
/// final downloadController = httpWrap.download(
///   url: 'https://example.com/file.zip',
///   saveDirectory: '/path/to/save',
/// );
/// downloadController.progressStream.listen((downloadInfo) {
///   print('Download state: ${downloadInfo.state}, Progress: ${downloadInfo.progress}%, Can Resume: ${downloadInfo.canResume}');
/// });
///
/// // To pause the download
/// downloadController.pause();
///
/// // To resume the download
/// downloadController.resume();
/// ```
class DownloadController {
  final Downloader _downloader;
  final Stream<DownloadInfo> progressStream;

  DownloadController(this._downloader, this.progressStream);

  void pause() => _downloader.pause();
  void resume() => _downloader.resume();
  bool isPaused() => _downloader.isPaused;
}
