/// The request file type include the following:
/// - [RequestFileFromBytes] for files from bytes.
/// - [RequestFileFromPath] for files from path.
/// - [RequestFileFromString] for files from string.
abstract class RequestFile {
  final String itemKey;

  RequestFile({required this.itemKey});
}
