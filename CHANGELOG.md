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
