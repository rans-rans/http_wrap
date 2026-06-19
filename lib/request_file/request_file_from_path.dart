part of './request_file.dart';

/// Multipart file sourced from an existing local file path.
class RequestFileFromPath extends RequestFile {
  /// Absolute or relative path to the file on disk.
  final String path;

  /// Creates a file part that reads bytes from [path] at send time.
  RequestFileFromPath({
    required super.itemKey,
    required this.path,
  });

  @override
  String toString() => 'RequestFileFromPath(path: $path)';

  @override
  bool operator ==(covariant RequestFileFromPath other) {
    if (identical(this, other)) return true;

    return other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
