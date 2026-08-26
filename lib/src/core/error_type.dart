part of 'http_wrap.dart';

/// Enumeration of error types that can occur during HTTP operations.
///
/// This enum represents the different categories of errors that may be
/// encountered when making HTTP requests or managing downloads.
enum ErrorType {
  /// Error occurred due to internet connectivity issues.
  internetError,

  /// Error occurred because the request exceeded the timeout duration.
  requestTimeout,

  /// HTTP 4XX Bad Request error - the request was malformed or invalid.
  status400,

  /// This indicates that URL, HEADERS, ETC are not setup correctly
  invalidSetup,

  /// HTTP 5XX Internal Server Error - the server encountered an unexpected condition.
  status500,

  /// An unknown or unclassified error occurred.
  unknown,
}
