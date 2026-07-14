import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../core/http_wrap.dart';
import 'download_state.dart';

/// Low-level download worker used by [DownloadController].
///
/// This class handles filename resolution, resumable range requests, file
/// writes, and progress callbacks.
class Downloader {
  StreamSubscription<List<int>>? _downloadSubscription;
  Completer<void>? _downloadCompleter;
  RandomAccessFile? _activeFileSink;
  File? _activeFile;
  http.Client? _activeClient;
  Function(DownloadInfo)? _progressCallback;
  bool? _activeCanResume;
  bool _isCanceled = false;

  /// This stores the progress of the download and it is initialized to zero
  double _progress = 0.0;

  /// Most recently computed progress percentage.
  double get progress => _progress;

  /// Whether the current transfer stream is paused.
  bool get isPaused {
    return _downloadSubscription?.isPaused == true;
  }

  /// Pauses the current transfer if it is actively streaming.
  void pause() {
    if (_downloadSubscription?.isPaused == true) return;
    _downloadSubscription?.pause();
  }

  /// Resumes the current transfer if it was previously paused.
  void resume() {
    if (_downloadSubscription?.isPaused == true) {
      _downloadSubscription?.resume();
    }
  }

  /// Cancels the active transfer and optionally deletes partial file output.
  Future<void> cancel() async {
    final hasActiveDownload =
        _downloadCompleter != null && _downloadCompleter!.isCompleted == false;

    _isCanceled = true;

    await _downloadSubscription?.cancel();
    _downloadSubscription = null;

    _closeActiveFileSink();
    _closeActiveClient();

    await _deleteActivePartialFile();

    if (hasActiveDownload) {
      _emitProgress(
        state: .canceled,
        progress: _progress,
      );

      if (_downloadCompleter?.isCompleted == false) {
        _downloadCompleter?.complete();
      }
    }
  }

  void _emitProgress({
    required DownloadState state,
    double? progress,
    Object? exception,
  }) {
    _progressCallback?.call(
      .new(
        state: state,
        canResume: _activeCanResume,
        progress: progress,
        exception: exception,
      ),
    );
  }

  void _closeActiveFileSink() {
    final fileSink = _activeFileSink;
    _activeFileSink = null;

    if (fileSink == null) return;

    try {
      fileSink.closeSync();
    } catch (_) {}
  }

  void _closeActiveClient() {
    _activeClient?.close();
    _activeClient = null;
  }

  Future<void> _deleteActivePartialFile() async {
    final file = _activeFile;
    if (file == null) return;

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  void _resetActiveTransferReferences() {
    _downloadSubscription = null;
    _downloadCompleter = null;
    _activeFileSink = null;
    _activeFile = null;
    _activeClient = null;
    _progressCallback = null;
    _activeCanResume = null;
  }

  String _resolveFileName({
    required Uri urlPath,
    required Map<String, String> headers,
  }) {
    final urlName = urlPath.pathSegments.lastWhere(
      (s) => s.isNotEmpty,
      orElse: () => '',
    );

    // Try to get content-disposition header (case-insensitive)
    String? contentDisposition = headers['content-disposition'];
    if (contentDisposition == null) {
      // Fallback: search for the header case-insensitively
      final dispositionKey = headers.keys.firstWhere(
        (key) => key.toLowerCase() == 'content-disposition',
        orElse: () => '',
      );
      if (dispositionKey.isNotEmpty) {
        contentDisposition = headers[dispositionKey];
      }
    }

    final fromDisposition = _fileNameFromContentDisposition(contentDisposition);
    if (fromDisposition != null && fromDisposition.isNotEmpty) {
      return fromDisposition;
    }

    // Only trust URL path filename when it looks like a real extension, not
    // tokenized segments that merely contain dots.
    if (_hasLikelyFileExtension(urlName)) {
      return urlName;
    }

    String? contentType = headers['content-type'];
    if (contentType == null) {
      // Fallback: search for the header case-insensitively
      final typeKey = headers.keys.firstWhere(
        (key) => key.toLowerCase() == 'content-type',
        orElse: () => '',
      );
      if (typeKey.isNotEmpty) {
        contentType = headers[typeKey];
      }
    }

    final extension = _extensionFromContentType(contentType);
    if (extension != null) {
      if (urlName.isNotEmpty) {
        return '$urlName.$extension';
      }
      return 'download.$extension';
    }

    if (urlName.isNotEmpty) return urlName;

    return 'download.bin';
  }

  bool _hasLikelyFileExtension(String fileName) {
    if (fileName.isEmpty || !fileName.contains('.')) {
      return false;
    }

    final lastDot = fileName.lastIndexOf('.');
    if (lastDot <= 0 || lastDot == fileName.length - 1) {
      return false;
    }

    final extension = fileName.substring(lastDot + 1);
    return RegExp(r'^[a-zA-Z0-9]{1,5}$').hasMatch(extension);
  }

  String? _fileNameFromContentDisposition(String? header) {
    if (header == null || header.isEmpty) {
      return null;
    }

    // Try filename*=UTF-8''encoded format first
    final filenameStar = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(header)?.group(1);
    if (filenameStar != null && filenameStar.isNotEmpty) {
      return Uri.decodeFull(filenameStar).replaceAll('"', '');
    }

    // Try filename="quoted" format
    final filenameQuoted = RegExp(
      r'filename="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(header)?.group(1);
    if (filenameQuoted != null && filenameQuoted.isNotEmpty) {
      return filenameQuoted;
    }

    // Try filename=unquoted format (no spaces)
    final filenameUnquoted = RegExp(
      r'filename=([^;\s]+)',
      caseSensitive: false,
    ).firstMatch(header)?.group(1);
    if (filenameUnquoted != null && filenameUnquoted.isNotEmpty) {
      return filenameUnquoted;
    }

    return null;
  }

  String? _extensionFromContentType(String? contentType) {
    if (contentType == null || contentType.isEmpty) {
      return null;
    }

    final normalized = contentType.split(';').first.trim().toLowerCase();
    const contentTypeMap = <String, String>{
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
      'image/gif': 'gif',
      'application/pdf': 'pdf',
      'application/zip': 'zip',
      'application/json': 'json',
      'text/plain': 'txt',
      'video/mp4': 'mp4',
      'audio/mpeg': 'mp3',
    };

    return contentTypeMap[normalized];
  }

  /// Downloads a remote file and reports lifecycle snapshots through [progress].
  ///
  /// The callback receives [DownloadInfo] updates for start, incremental
  /// progress, completion, and error states.
  Future<void> download({
    required String url,
    required String saveDirectory,
    Map<String, String>? headers,
    required Function(DownloadInfo) progress,
  }) async {
    try {
      if (_downloadCompleter != null &&
          _downloadCompleter?.isCompleted == false) {
        throw StateError(
          'A download is already running. Cancel it before starting another.',
        );
      }

      _isCanceled = false;
      _progressCallback = progress;

      final urlPath = Uri.parse(url);

      final canResumeRequest = await http.head(
        urlPath,
        headers: {
          // ignore: use_null_aware_elements
          if (headers != null) ...headers,
        },
      );
      final canResume = canResumeRequest.headers['accept-ranges'] == 'bytes';

      final fileName = _resolveFileName(
        urlPath: urlPath,
        headers: canResumeRequest.headers,
      );
      final savePath = '$saveDirectory${Platform.pathSeparator}$fileName';

      final file = File(savePath);
      await file.parent.create(recursive: true).onError((e, s) {
        throw s;
      });
      _activeFile = file;
      final fileExists = await file.exists();

      int downloadedBytes = fileExists ? file.lengthSync() : 0;
      final fileSink = file.openSync(
        mode: fileExists ? .append : .write,
      );
      _activeFileSink = fileSink;

      int totalBytes = 0;
      _activeCanResume = canResume;

      double getProgress() {
        final progress = downloadedBytes != 0 && totalBytes != 0
            ? (downloadedBytes / totalBytes) * 100
            : 0.0;
        _progress = progress;
        return progress;
      }

      try {
        final request = http.Request(
          HttpMethod.get.value,
          urlPath,
        );

        request.headers.addAll(
          {
            if (downloadedBytes > 0) "Range": "bytes=$downloadedBytes-",
            // ignore: use_null_aware_elements
            if (headers != null) ...headers,
          },
        );

        final activeClient = http.Client();
        _activeClient = activeClient;
        final streamResponse = await activeClient.send(request);
        totalBytes = streamResponse.contentLength ?? 0;

        _emitProgress(
          state: .notStarted,
          progress: getProgress(),
        );
        final downloadCompleter = Completer<void>();
        _downloadCompleter = downloadCompleter;
        _downloadSubscription =
            streamResponse.stream.listen(
              (data) {
                _downloadSubscription?.pause();
                try {
                  fileSink.writeFromSync(data);
                  downloadedBytes = downloadedBytes + data.length;
                  _emitProgress(
                    state: .downloading,
                    progress: getProgress(),
                  );
                } finally {
                  _downloadSubscription?.resume();
                }
              },
              onDone: () {
                _closeActiveFileSink();

                if (_isCanceled == false) {
                  _emitProgress(
                    state: .completed,
                    progress: getProgress(),
                  );
                }

                if (!downloadCompleter.isCompleted) {
                  downloadCompleter.complete();
                }
              },
              onError: (Object error, StackTrace stackTrace) {
                _closeActiveFileSink();

                if (_isCanceled == false) {
                  _emitProgress(
                    state: .failed,
                    progress: getProgress(),
                    exception: (error, stackTrace),
                  );
                }

                if (!downloadCompleter.isCompleted) {
                  if (_isCanceled) {
                    downloadCompleter.complete();
                  } else {
                    downloadCompleter.completeError(error, stackTrace);
                  }
                }
              },
              cancelOnError: true,
            )..onError((e, st) {
              if (!downloadCompleter.isCompleted) {
                if (_isCanceled) {
                  downloadCompleter.complete();
                } else {
                  downloadCompleter.completeError(e, st ?? .current);
                  _emitProgress(
                    state: .failed,
                    progress: getProgress(),
                    exception: (e, st),
                  );
                }
              }
            });
        await downloadCompleter.future;
      } catch (e) {
        _closeActiveFileSink();

        if (_isCanceled == false) {
          _emitProgress(
            state: .failed,
            progress: this.progress,
            exception: e,
          );
        }
      } finally {
        _closeActiveClient();
        _resetActiveTransferReferences();
      }
    } catch (e) {
      rethrow;
    }
  }
}
