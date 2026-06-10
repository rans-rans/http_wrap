import 'package:http_wrap/request_file_type/request_file.dart';

class RequestFileFromString extends RequestFile {
  final String data;
  RequestFileFromString({
    required this.data,
    required super.itemKey,
  });

  @override
  bool operator ==(covariant RequestFileFromString other) {
    if (identical(this, other)) return true;

    return other.data == data;
  }

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'RequestFileFromString(data: $data, key: $itemKey)';
}
