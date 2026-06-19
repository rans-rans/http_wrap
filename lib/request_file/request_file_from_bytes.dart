part of './request_file.dart';

/// Multipart file sourced from in-memory bytes.
class RequestFileFromBytes extends RequestFile {
  /// File bytes to upload.
  final List<int> bytes;

  /// Creates a file part from raw byte data.
  RequestFileFromBytes({
    required super.itemKey,
    required this.bytes,
  });

  @override
  String toString() => 'RequestFileFromBytes(bytes: $bytes, key: $itemKey)';
}
