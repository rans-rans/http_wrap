// ignore_for_file: public_member_api_docs, sort_constructors_first
enum DownloadState {
  /// The download has not started yet.
  notStarted,

  /// The download is in progress.
  downloading,

  /// The download has completed successfully.
  completed,

  /// The download has failed.
  failed,
}

class DownloadInfo {
  /// This show the download state
  ///  - [notStarted] the download has not started yet.
  ///  - [downloading] the download is in progress.
  ///  - [completed] the download has completed successfully.
  ///  - [failed] the download has failed.
  final DownloadState state;

  /// This shows the progress of the download as a percentage (0.0 to 100.0).
  /// Save it to a variable or some kind of state
  final double? progress;

  /// This shows if the server supports resumable downloads.
  final bool? canResume;

  final Object? exception;

  const DownloadInfo({
    this.state = .notStarted,
    this.progress,
    this.canResume,
    this.exception,
  });
}
