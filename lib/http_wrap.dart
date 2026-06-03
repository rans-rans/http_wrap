import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_wrap/http_method.dart';

part './http_response.dart';

class _HttpException implements Exception {
  final String message;

  _HttpException(this.message);

  @override
  String toString() => message;
}

class HttpWrap {
  String? _baseUrl;
  Map<String, String>? _defaultHeaders;
  int _timeout = 100;

  static final HttpWrap _instance = HttpWrap._internal();
  factory HttpWrap() => _instance;

  HttpWrap._internal() {
    config();
  }

  void config({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    int? timeout,
  }) {
    _baseUrl = baseUrl ?? _baseUrl;
    _defaultHeaders = defaultHeaders ?? _defaultHeaders;
    _timeout = timeout ?? _timeout;
  }

  Future<String?> getPlatformVersion() async {
    return "0.0";
  }

  Future<HttpResponse> request({
    required HttpMethod method,
    required String endpoint,
    String? baseUrl,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    List<({String key, String? path})> files = const [],
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
        final shouldUseMultipart = useFormData || files.isNotEmpty;

        if (shouldUseMultipart == false) {
          request = http.Request(method.value, uri)
            ..headers.addAll(resolvedHeaders)
            ..body = json.encode(
              (fields ?? {})..removeWhere((k, v) => v == null),
            );
        } else {
          final requestHeaders = Map<String, String>.from(resolvedHeaders)
            ..removeWhere(
              (key, value) => key.toLowerCase() == 'content-type',
            );

          Map<String, String> requestFields = {};
          fields?.forEach((k, v) {
            if (v == null) return;

            final stringValue = v.toString();
            if (stringValue.isEmpty) return;

            requestFields[k] = stringValue;
          });

          request =
              http.MultipartRequest(
                  method.value,
                  uri,
                )
                ..headers.addAll(requestHeaders)
                ..fields.addAll(requestFields);

          for (var i = 0; i < files.length; i++) {
            (request as http.MultipartRequest).files.add(
              await http.MultipartFile.fromPath(files[i].key, files[i].path!),
            );
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

      if (streamedResponse.statusCode >= 500) {
        throw _HttpException('Server error. Please try again later');
      }

      // Parsing the response body for data
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = json.decode(response.body);

      // We check if the server sent a success response, if not we check if it sent a message and throw that as an error, otherwise we throw a generic error
      if (streamedResponse.statusCode > 299) {
        throw _HttpException("Request invalid");
      }

      // We can now return the response body as the request was successful
      return .new(
        message: "Request completed",
        data: responseBody,
        success: true,
      );
    } catch (e) {
      if (e is http.ClientException || e is SocketException) {
        return const .new(
          message: "Check your network connection",
          data: null,
          success: false,
        );
      }
      return .new(
        message: e.toString(),
        data: null,
        success: false,
      );
    }
  }
}
