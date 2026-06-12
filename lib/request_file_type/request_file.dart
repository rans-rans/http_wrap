part 'request_file_from_bytes.dart';
part 'request_file_from_path.dart';
part 'request_file_from_string.dart';

/// Base type for multipart file inputs accepted by `requestFiles`.
///
/// Supported implementations:
/// - [RequestFileFromBytes] for in-memory file bytes.
/// - [RequestFileFromPath] for files loaded from a local path.
/// - [RequestFileFromString] for string content sent as a file part.
abstract class RequestFile {
  final String itemKey;

  RequestFile({required this.itemKey});
}
