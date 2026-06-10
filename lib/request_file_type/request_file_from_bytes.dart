import 'package:http_wrap/request_file_type/request_file.dart';

class RequestFileFromBytes extends RequestFile {
  final List<int> bytes;
  RequestFileFromBytes({
    required super.itemKey,
    required this.bytes,
  });

  @override
  String toString() => 'RequestFileFromBytes(bytes: $bytes, key: $itemKey)';
}
