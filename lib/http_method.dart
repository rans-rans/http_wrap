part of 'http_wrap.dart';

/// Supported HTTP verbs for [HttpWrap.request].
enum HttpMethod {
  /// Retrieves data without modifying server state.
  get,

  /// Creates a new resource.
  post,

  /// Partially updates an existing resource.
  patch,

  /// Replaces an existing resource.
  put,

  /// Removes an existing resource.
  delete;

  /// Uppercase HTTP verb used by the underlying `http` client.
  String get value {
    return switch (this) {
      .get => 'GET',
      .post => 'POST',
      .patch => 'PATCH',
      .put => 'PUT',
      .delete => 'DELETE',
    };
  }
}
