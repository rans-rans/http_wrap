import 'dart:async';

import 'download_state.dart';
import 'downloader.dart';

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
  /// Internal downloader instance that performs stream/file operations.
  final Downloader _downloader;

  /// Emits [DownloadInfo] updates while a file is being downloaded.
  ///
  /// Listen to this stream to update progress bars and react to completion or
  /// failure states.
  final Stream<DownloadInfo> progressStream;

  /// Creates a controller around a [Downloader] and its progress stream.
  DownloadController(this._downloader, this.progressStream);

  /// Temporarily pauses the active transfer when supported by the stream.
  void pause() => _downloader.pause();

  /// Continues a paused transfer.
  void resume() => _downloader.resume();

  /// Returns `true` when the underlying download stream is currently paused.
  bool isPaused() => _downloader.isPaused;
}
