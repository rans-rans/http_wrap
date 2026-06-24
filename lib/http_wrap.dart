/// Lightweight HTTP wrapper for Dart and Flutter with unified API surface.
///
/// This is the main entry point for http_wrap. All public types and functionality
/// are exported from this library, providing a clean, single import path:
///
/// ```dart
/// import 'package:http_wrap/http_wrap.dart';
/// ```
///
/// Once imported, you have access to:
/// - [HttpWrap]: Main HTTP client singleton for making requests
/// - [HttpResponse]: Unified response object for all requests
/// - [HttpMethod]: Enum for HTTP verbs (GET, POST, PUT, PATCH, DELETE, HEAD)
/// - [DownloadController]: Controller for managing file downloads
/// - [DownloadInfo]: Download progress and state tracking
/// - [RequestFile] and implementations: File attachment types for multipart requests
/// - [HttpWrapPlatform]: Platform-specific integration interface
library;

export 'src/core/http_wrap.dart';
export 'src/download/download_controller.dart';
export 'src/download/download_state.dart';
export 'src/download/downloader.dart';
export 'src/request_file/request_file.dart';
