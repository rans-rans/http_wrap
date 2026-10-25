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

  /// HTTP status code for a successfully processed response or handled HTTP error.
  ///
  /// May be null for setup, network, timeout, or response-decoding failures.
  final int? statusCode;

  /// Optional error metadata available for failed requests.
  ///
  /// For handled HTTP errors, [HttpWrap.request] returns a named record with
  /// `errorCode` and `errorData`. The payload is decoded JSON for handled client
  /// errors or the raw body for server errors. For network and other client-side
  /// failures, this is the caught exception instead.
  /// Callers constructing their own responses may supply other payload types.
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
