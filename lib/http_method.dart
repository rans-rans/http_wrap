enum HttpMethod {
  get,
  post,
  patch,
  put,
  delete;

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
