part of './request_file.dart';

class RequestFileFromPath extends RequestFile {
  final String path;

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
