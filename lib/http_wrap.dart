import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:http_wrap/request_file_type/request_file.dart';

part 'http_response.dart';
part 'http_method.dart';
part 'http_wrap_multipart_fields.dart';

class _HttpException implements Exception {
  final String message;
  final int? code;

  _HttpException(this.message, [this.code]);

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
    required String endpoint,
    String? baseUrl,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    @Deprecated('Use requestFiles instead.')
    List<({String key, String? path})> files = const [],
    List<RequestFile> requestFiles = const [],
    bool useFormData = false,
  }) async {
    try {
      final url = (baseUrl ?? _baseUrl)?.replaceAll("https://", '');
      if (url == null) {
        return const .new(
          message: "Url not configured",
          data: null,
          success: false,
        );
      }
      final uri = Uri.https(url, endpoint, queryParams);

      // Creating the request object based on the HTTP method
      late http.BaseRequest request;
      final resolvedHeaders = {
        ...(headers ?? _defaultHeaders ?? {}),
      };

      if (method == .get) {
        request = http.Request(method.value, uri)
          ..headers.addAll(resolvedHeaders)
          ..body = json.encode(
            (fields ?? {})..removeWhere((k, v) => v == null),
          );
      } else {
        final shouldUseMultipart =
            useFormData || requestFiles.isNotEmpty || files.isNotEmpty;

        if (shouldUseMultipart == false) {
          request = http.Request(method.value, uri)
            ..headers.addAll(resolvedHeaders)
            ..body = jsonEncode(
              (fields ?? {})..removeWhere((k, v) => v == null),
            );
        } else {
          final requestHeaders = Map<String, String>.from(resolvedHeaders)
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
        Duration(seconds: _timeout),
        onTimeout: () => throw _HttpException(
          "Request timed out. Please try again later",
        ),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (streamedResponse.statusCode >= 500) {
        throw _HttpException(
          'Server error. Please try again later',
          streamedResponse.statusCode,
        );
      }

      // Parsing the response body for data
      final responseBody = await Isolate.run(() => json.decode(response.body));

      // We check if the server sent a success response, if not we check if it sent a message and throw that as an error, otherwise we throw a generic error
      if (streamedResponse.statusCode > 299) {
        return .new(
          data: responseBody,
          success: false,
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
        data: responseBody,
        success: true,
      );
    } catch (e) {
      if (e is _HttpException) {
        return .new(
          message: e.toString(),
          data: null,
          success: false,
          errorData: (errorCode: e.code, errorData: null),
        );
      }
      if (e is http.ClientException || e is SocketException) {
        return const .new(
          message: "Check your network connection",
          data: null,
          success: false,
          errorData: (errorCode: null, errorData: null),
        );
      }
      return .new(
        message: e.toString(),
        data: null,
        success: false,
        errorData: (errorCode: null, errorData: null),
      );
    }
  }
}
