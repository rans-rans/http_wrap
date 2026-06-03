part of './http_wrap.dart';

class HttpResponse {
  final String? message;
  final dynamic data;
  final bool? success;

  const HttpResponse({
    required this.message,
    required this.data,
    required this.success,
  });
}
