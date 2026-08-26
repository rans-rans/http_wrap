import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import '../download/download_controller.dart';
import '../download/download_state.dart';
import '../download/downloader.dart';
import '../request_file/request_file.dart';

part 'http_response.dart';
part 'http_method.dart';
part 'http_wrap_multipart_fields.dart';
part "error_type.dart";

/// Custom Exception to handle internal errors
class _HttpException implements Exception {
  final String message;
  final ErrorType? errorType;

  _HttpException(this.message, [this.errorType]);

  @override
  String toString() => message;
}

/// Lightweight HTTP wrapper with shared configuration and typed responses.
///
/// [HttpWrap] uses a singleton instance so configuration can be reused across
/// your app without passing a client object everywhere.
class HttpWrap {
  String? _baseUrl;
  Map<String, String>? _defaultHeaders;
  int _timeout = 100;

  static final HttpWrap _instance = HttpWrap._internal();

  /// Returns the shared [HttpWrap] instance.
  factory HttpWrap() => _instance;

  HttpWrap._internal() {
    config();
  }

  /// Sets global defaults used by every request unless overridden.
  ///
  /// - [baseUrl]: Host used to build request URLs.
  /// - [defaultHeaders]: Headers merged into each request by default.
  /// - [timeout]: Request timeout in seconds.
  void config({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    int? timeout,
  }) {
    _baseUrl = baseUrl ?? _baseUrl;
    _defaultHeaders = defaultHeaders ?? _defaultHeaders;
    _timeout = timeout ?? _timeout;
  }

  /// Initiates a file download and returns a [DownloadController] to track its progress.
  /// DownloadeController is returned from this function.
  ///
  /// Using the download controller, you can listen to download progress, pause, resume, and cancel downloads.
  /// The [DownloadController] contains [DownloadInfo] which provides the current state of the download, the progress percentage, and whether the server supports resumable downloads.
  ///
  /// Example usage:
  /// ```dart
  /// final downloadController = httpWrap.download(
  ///   url: 'https://example.com/file.zip',
  ///   saveDirectory: '/path/to/save',
  /// );
  /// downloadController.progressStream.listen((downloadInfo) {
  ///   print('Download state: ${downloadInfo.state}, Progress: ${downloadInfo.progress}%, Can Resume: ${downloadInfo.canResume}');
  /// });
  /// // To pause the download
  /// downloadController.pause();
  /// // To resume the download
  /// downloadController.resume();
  ///
  /// // To cancel and delete partial file
  /// await downloadController.cancel();
  /// ```
  DownloadController download({
    required String url,
    required String saveDirectory,
    Map<String, String>? headers,
  }) {
    final progressController = StreamController<DownloadInfo>();
    final downloader = Downloader();

    downloader.download(
      url: url,
      headers: headers,
      saveDirectory: saveDirectory,
      progress: (info) {
        if (progressController.isClosed) return;

        progressController.add(info);

        if (info.state == .completed ||
            info.state == .failed ||
            info.state == .canceled) {
          progressController.close();
        }
      },
    );

    return DownloadController(downloader, progressController.stream);
  }

  /// Sends an HTTP request and returns a normalized [HttpResponse].
  ///
  /// [method] and [endpoint] are required for every request.
  ///
  /// - [baseUrl] overrides the globally configured host for one request.
  /// - [fields] are sent as JSON for normal requests or as form fields for
  ///   multipart requests.
  /// - [queryParams] are appended to the URL.
  /// - [headers] override or extend global default headers.
  /// - [requestFiles] attaches multipart files from path, bytes, or string.
  /// - [files] is deprecated and kept for backward compatibility.
  /// - [useFormData] forces multipart mode even when no files are provided.
  ///
  /// Returns `success: false` for network errors, timeout failures, and
  /// non-2xx HTTP responses.
  ///
  /// For failed responses, [HttpResponse.errorData] includes additional
  /// diagnostics such as HTTP status code and server error payload.
  Future<HttpResponse> request({
    required HttpMethod method,
    String? endpoint,
    String? baseUrl,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    Duration? timeout,
    @Deprecated('Use requestFiles instead.')
    List<({String key, String? path})> files = const [],
    List<RequestFile> requestFiles = const [],
    bool useFormData = false,
  }) async {
    try {
      final url = (baseUrl ?? _baseUrl)
          ?.replaceAll("https://", '')
          .replaceAll("http://", "");
      if (url == null) {
        return const .new(
          errorType: .invalidSetup,
          data: null,
          success: false,
        );
      }
      final uri = Uri.https(url, endpoint ?? "", queryParams);

      // Creating the request object based on the HTTP method
      late http.BaseRequest request;
      final resolvedHeaders = {
        ...(headers ?? _defaultHeaders ?? {}),
      };

      if (method == .get) {
        final requestItem = http.Request(method.value, uri)
          ..headers.addAll(resolvedHeaders);
        if (fields != null && fields.isEmpty == false) {
          requestItem.body = json.encode(
            fields..removeWhere((k, v) => v == null),
          );
        }
        request = requestItem;
      } else {
        final shouldUseMultipart =
            useFormData || requestFiles.isNotEmpty || files.isNotEmpty;

        if (shouldUseMultipart == false) {
          final requestItem = http.Request(method.value, uri)
            ..headers.addAll(resolvedHeaders);
          if (fields != null && fields.isEmpty == false) {
            requestItem.body = json.encode(
              fields..removeWhere((k, v) => v == null),
            );
          }

          request = requestItem;
        } else {
          final requestHeaders = resolvedHeaders
            ..removeWhere(
              (key, value) => key.toLowerCase() == 'content-type',
            );

          final requestFields = _buildMultipartFields(fields);

          request =
              http.MultipartRequest(
                  method.value,
                  uri,
                )
                ..headers.addAll(requestHeaders)
                ..fields.addAll(requestFields);

          if (requestFiles.isNotEmpty) {
            for (var file in requestFiles) {
              final multipartPartFile = switch (file) {
                RequestFileFromBytes() => http.MultipartFile.fromBytes(
                  file.itemKey,
                  file.bytes,
                ),
                RequestFileFromPath() => await http.MultipartFile.fromPath(
                  file.itemKey,
                  file.path,
                ),
                RequestFileFromString() => http.MultipartFile.fromString(
                  file.itemKey,
                  file.data,
                ),
                _ => throw _HttpException('Unsupported request file type'),
              };

              (request as http.MultipartRequest).files.add(multipartPartFile);
            }
          } else if (files.isNotEmpty) {
            for (var i = 0; i < files.length; i++) {
              (request as http.MultipartRequest).files.add(
                await http.MultipartFile.fromPath(files[i].key, files[i].path!),
              );
            }
          }
        }
      }
      // We first check if the server even sent a response
      final streamedResponse = await request.send().timeout(
        timeout ?? Duration(seconds: _timeout),
        onTimeout: () {
          throw _HttpException(
            "Request timed out. Please try again later",
            .requestTimeout,
          );
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (streamedResponse.statusCode >= 500) {
        return .new(
          errorType: .status500,
          success: false,
          data: null,
          message: streamedResponse.reasonPhrase,
          errorData: (
            errorCode: streamedResponse.statusCode,
            errorData: response.body,
          ),
        );
      }

      // Parsing the response body in a separate isolate because response might be large
      final responseBodyString = response.body;
      final responseBody = await Isolate.run(
        () => json.decode(responseBodyString),
      );

      // We check if the server sent a success response, if not we check if it sent a message and throw that as an error, otherwise we throw a generic error
      if (streamedResponse.statusCode > 299) {
        return .new(
          data: responseBody,
          success: false,
          errorType: .status400,
          message: "Request invalid",
          errorData: (
            errorCode: streamedResponse.statusCode,
            errorData: responseBody,
          ),
        );
      }

      // We can now return the response body as the request was successful
      return .new(
        message: "Request completed",
        errorType: null,
        data: responseBody,
        success: true,
      );
    } catch (e) {
      if (e is _HttpException) {
        return .new(
          data: null,
          errorType: e.errorType,
          success: false,
          errorData: (errorCode: null, errorData: null),
        );
      }
      if (e is http.ClientException || e is SocketException) {
        return .new(
          errorType: .internetError,
          data: null,
          message: e.toString(),
          success: false,
          errorData: (errorCode: null, errorData: null),
        );
      }
      return .new(
        errorType: .unknown,
        message: e.toString(),
        data: null,
        success: false,
        errorData: (errorCode: null, errorData: null),
      );
    }
  }
}
