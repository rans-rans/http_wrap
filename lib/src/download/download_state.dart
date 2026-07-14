enum DownloadState {
  /// The download has not started yet.
  notStarted,

  /// The download is in progress.
  downloading,

  /// The download was canceled by the caller.
  canceled,

  /// The download has completed successfully.
  completed,

  /// The download has failed.
  failed,
}

/// Snapshot of one point in a download flow.
/// You usually receive instances of this model from the download progress stream exposed by the controller.
class DownloadInfo {
  /// Tells you where the download currently is in its lifecycle.
  ///
  /// Possible values are:
  /// - [DownloadState.notStarted] before bytes are received.
  /// - [DownloadState.downloading] while bytes are actively streaming.
  /// - [DownloadState.canceled] when the transfer is stopped manually.
  /// - [DownloadState.completed] once the file is fully written.
  /// - [DownloadState.failed] if an error interrupts the transfer.
  final DownloadState state;

  /// Current progress percentage from `0.0` to `100.0`.
  ///
  /// This can be `null` in early or error states, so it is safe to render a
  /// fallback in your UI while waiting for the first progress update.
  final double? progress;

  /// Whether the remote server supports byte ranges for resume support.
  final bool? canResume;

  /// Raw exception payload emitted by the downloader when the transfer fails.
  final Object? exception;

  /// Snapshot of one point in a download flow.
  ///
  /// You usually receive instances of this model from the download
  /// progress stream exposed by the controller.
  const DownloadInfo({
    this.state = .notStarted,
    this.progress,
    this.canResume,
    this.exception,
  });
}
