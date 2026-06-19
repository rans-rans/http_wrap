part of './request_file.dart';

/// Multipart file sourced from plain text content.
class RequestFileFromString extends RequestFile {
  /// Text payload that will be sent as the file content.
  final String data;

  /// Creates a file part from a string value.
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
