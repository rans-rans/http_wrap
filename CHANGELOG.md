## 1.3.3

* Added cancel support for active downloads via `DownloadController.cancel()`.
* Removed unnecessary storage permissions (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE`) from the example app's Android manifest.

## 1.3.2

* Added `headers` support to the head request used by download validation.

## 1.3.1

* Added `headers` parameter to the download function for custom HTTP request headers.

## 1.3.0

* **BREAKING**: Reorganized package structure for cleaner public API surface and to fix pub.dev documentation generation conflicts.
* All implementation files now reside under `lib/src/` (internal) instead of polluting the public import surface.
* Only `package:http_wrap/http_wrap.dart` is now exposed as the public entry point.
* Removed duplicate re-export paths and compatibility shims to eliminate IDE autocomplete clutter and dartdoc conflicts.
* Import recommendations in IDEs now show only the single recommended path: `import 'package:http_wrap/http_wrap.dart';`
* Project structure now follows Dart conventions: public libraries at `lib/`, internal code under `lib/src/`.

## 1.2.1

* Added project documentation comments


## 1.2.0

* Added file download support with `Downloader` class for downloading files to local storage.
* Downloads support pause and resume functionality for better user control.
* Added real-time download progress tracking.
* Implemented `DownloadController` for managing concurrent downloads with automatic cleanup.
* Added `DownloadState` enum to track download progress, completion, and error states.
* Includes download examples in the example app.

## 1.1.6

* Fixed isolate crash when decoding the response body of a multipart request.
* The response body string is now extracted before spawning the isolate so only a plain `String` crosses the isolate boundary, avoiding the `ByteStream` unsendable object error.

## 1.1.5

* Changed multipart `fields` encoding for `List` and `Map` values to Laravel/PHP-style bracketed keys (for example: `items[0]`, `meta[name]`) instead of JSON strings.
* Fixed multipart payload handling to avoid sending array values as string literals like `"[]"`.
* Clarified multipart empty-list behavior: explicit empty lists are omitted because multipart form fields cannot represent `[]` directly.
* Refactored multipart field flattening to an iterative (non-recursive) implementation and moved it into a dedicated part file.

## 1.1.4

* Refreshed package and example documentation to match the current `fields`, `queryParams`, and `requestFiles` API.
* Improved generated plugin comments and package metadata to better describe the Dart-first request flow.
* Cleaned up internal library part declarations for request file and response types without changing the public API.

## 1.1.3
* Added another fix to remove fields with empty or null value for multipart request

## 1.1.2

* Removed empty fields for for request field request data


## 1.1.1

* Fixed multipart form field serialization for complex values.
* Multipart `fields` values that are `List` or `Map` are now JSON-encoded before sending.
* Added documentation notes clarifying multipart serialization behavior.

## 1.1.0

* Added `requestFiles` support for multipart uploads using `RequestFileFromPath`, `RequestFileFromBytes`, and `RequestFileFromString`.
* Deprecated the `files` parameter in `request()` in favor of `requestFiles`.
* Kept backward compatibility for `files` so existing integrations continue to work.
* Updated multipart request handling so requests switch to multipart mode when `requestFiles` is provided.
* Refactored request file type handling to clearer Dart pattern matching.

## 1.0.0

* Initial release of the `http_wrap` plugin.
* Added a simple request wrapper with support for headers, query params, and request body fields.
* Added multipart/form-data support for file uploads.
* Added unified `HttpResponse` handling with optional error metadata (`errorCode`, `errorData`).
