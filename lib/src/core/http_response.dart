part of './http_wrap.dart';

/// Standard response object returned by [HttpWrap.request].
class HttpResponse {
  /// Human-readable status or error description.
  final String? message;

  /// This indicates which kind of error, if the request fails
  final ErrorType? errorType;

  /// Decoded response payload from the server.
  final dynamic data;

  /// `true` when request completed successfully, otherwise `false`.
  final bool success;

  /// The status code of the request
  /// - `errorCode`: HTTP status code(eg. 200, 404, etc) WHEN AVAILABLE.
  final int? statusCode;

  /// Optional error metadata available for failed requests.
  ///
  ///  The error code will be null when the request fails due to network issues or other client-side errors.
  /// - `errorData`: Response payload returned by the server on failure.
  final dynamic errorData;

  /// Creates a response wrapper for successful and failed requests.
  const HttpResponse({
    this.message,
    required this.errorType,
    required this.data,
    this.success = false,
    this.errorData,
    this.statusCode,
  });
}
