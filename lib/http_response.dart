part of './http_wrap.dart';

/// Standard response object returned by [HttpWrap.request].
class HttpResponse {
  /// Human-readable status or error description.
  final String? message;

  /// Decoded response payload from the server.
  final dynamic data;

  /// `true` when request completed successfully, otherwise `false`.
  final bool success;

  /// Optional error metadata available for failed requests.
  ///
  /// - `errorCode`: HTTP status code when available.
  /// - `errorData`: Response payload returned by the server on failure.
  final ({int? errorCode, dynamic errorData})? errorData;

  /// Creates a response wrapper for successful and failed requests.
  const HttpResponse({
    required this.message,
    required this.data,
    this.success = false,
    this.errorData,
  });
}
