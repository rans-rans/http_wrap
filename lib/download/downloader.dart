import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_wrap/core/http_wrap.dart';
import 'package:http_wrap/download/download_state.dart';

class Downloader {
  StreamSubscription<List<int>>? _downloadSubscription;

  double _progress = 0.0;
  double get progress => _progress;

  bool get isPaused {
    return _downloadSubscription?.isPaused == true;
  }

  void pause() {
    if (_downloadSubscription?.isPaused == true) return;
    _downloadSubscription?.pause();
  }

  void resume() {
    if (_downloadSubscription?.isPaused == true) {
      _downloadSubscription?.resume();
    }
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

  Future<void> download({
    required String url,
    required String saveDirectory,
    required Function(DownloadInfo) progress,
  }) async {
    try {
      final urlPath = Uri.parse(url);

      final canResumeRequest = await http.head(urlPath);
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
      final fileExists = await file.exists();

      int downloadedBytes = fileExists ? file.lengthSync() : 0;
      final fileSink = file.openSync(
        mode: fileExists ? .append : .write,
      );

      int totalBytes = 0;

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
          },
        );

        final streamResponse = await http.Client().send(request);
        totalBytes = streamResponse.contentLength ?? 0;

        progress(
          .new(
            state: .notStarted,
            canResume: canResume,
            progress: getProgress(),
          ),
        );
        final downloadCompleter = Completer<void>();
        _downloadSubscription =
            streamResponse.stream.listen(
              (data) {
                _downloadSubscription?.pause();
                try {
                  fileSink.writeFromSync(data);
                  downloadedBytes = downloadedBytes + data.length;
                  progress(
                    .new(
                      state: .downloading,
                      canResume: canResume,
                      progress: getProgress(),
                    ),
                  );
                } finally {
                  _downloadSubscription?.resume();
                }
              },
              onDone: () {
                fileSink.closeSync();
                progress(
                  .new(
                    state: .completed,
                    canResume: canResume,
                    progress: getProgress(),
                  ),
                );
                if (!downloadCompleter.isCompleted) {
                  downloadCompleter.complete();
                }
              },
              onError: (Object error, StackTrace stackTrace) {
                progress(
                  .new(
                    state: .failed,
                    progress: getProgress(),
                    exception: (error, stackTrace),
                    canResume: canResume,
                  ),
                );
                fileSink.closeSync();
                if (!downloadCompleter.isCompleted) {
                  downloadCompleter.completeError(error, stackTrace);
                }
              },
              cancelOnError: true,
            )..onError((e, st) {
              if (!downloadCompleter.isCompleted) {
                downloadCompleter.completeError(e, st ?? .current);
                progress(
                  .new(
                    state: .failed,
                    progress: getProgress(),
                    exception: (e, st),
                    canResume: canResume,
                  ),
                );
              }
            });
        await downloadCompleter.future;
      } catch (e) {
        fileSink.closeSync();
        progress(
          .new(
            state: .failed,
            progress: this.progress,
            canResume: canResume,
            exception: e,
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
