# http_wrap

A lightweight Dart/Flutter wrapper around the `http` package to make API calls
simpler.

Set your request values (`fields`, `headers`, `queryParams`, `requestFiles`,
etc.) and call one method.

## Features

- Simple, single entry-point request API
- Base URL and default header configuration
- Query params support
- JSON request body support
- Multipart/form-data support for file uploads
- File download support (pause, resume, download progress, cancel)
- Unified response object (`HttpResponse`)
- HTTP status codes and structured error classifications (`ErrorType`)
- Structured error metadata (`errorCode`, `errorData`) for failed requests
- Basic timeout and network error handling

## Requirements

- Dart `>=3.13.4 <4.0.0` and a compatible Flutter SDK
- Android API 24+ or iOS 13.0+ for the bundled native plugin
- Flutter Web is not supported because the package uses `dart:io`

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
    http_wrap: ^2.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:http_wrap/http_wrap.dart';

final api = HttpWrap()
	..config(
		baseUrl: 'https://jsonplaceholder.typicode.com',
		timeout: 30,
		defaultHeaders: {
			'Content-Type': 'application/json',
			'Accept': 'application/json',
		},
	);
```

### GET Request With Query Params

```dart
final res = await api.request(
	method: .get,
	endpoint: '/comments',
	queryParams: {
		'postId': '1',
	},
);

if (res.success) {
	// /comments returns a top-level JSON array, not an object with a data key.
	final comments = res.data as List;
	for (final comment in comments) {
		print('${comment['name']} (${comment['email']})');
	}
} else {
	print(res.message);
}
```

### POST Request With JSON Body

```dart
final res = await api.request(
	method: .post,
	endpoint: '/posts',
	fields: {
		'title': 'Hello',
		'body': 'An example post',
		'userId': 1,
	},
	headers: {
		'Content-Type': 'application/json',
		'Authorization': 'Bearer your_token_here',
	},
);
```

### Multipart/Form-Data Request (File Upload)

Use your own upload API; JSONPlaceholder does not support file uploads.

```dart
import 'package:http_wrap/http_wrap.dart';

final res = await api.request(
	method: .post,
	baseUrl: 'https://your-api.example',
	endpoint: '/upload',
	useFormData: true,
	fields: {
		'title': 'Profile photo',
	},
	requestFiles: [
		RequestFileFromPath(itemKey: 'file', path: '/absolute/path/to/image.jpg'),
	],
);
```

### File Download

NOTE: This download function doesn't check the validity of the URL or the save
directory. Make sure to handle any necessary permissions and validations before
calling this function.

The GOOD news is when you start a download, you can close/stop the app entirely,
come back to the app and if the download url is the same, the package will
automatically resume from the exact point where it was interupted. The only
thing to keep safe is the download url.

```dart
final downloadController = api.download(
	url: 'https://example.com/files/report.pdf',
	saveDirectory: '/absolute/path/to/save/directory',
);

// Use the controller to get the progress stream
downloadController.progressStream.listen((info) {
	print('State: ${info.state}');
	print('Progress: ${info.progress?.toStringAsFixed(2)}%');
	print('Can resume: ${info.canResume}');
});

// Use the controller to PAUSE the current download stream.
downloadController.pause();

// Use the controller to RESUME the paused download stream.
downloadController.resume();

// Cancel and cleanup any partial file.
await downloadController.cancel();

// Use the controller to see whether the stream is paused.
downloadController.isPaused();
```

## API Reference

### `config`

```dart
void config({
	String? baseUrl,
	Map<String, String>? defaultHeaders,
	int? timeout,
})
```

- `baseUrl`: Full base URL, including `http://` or `https://`; the scheme is preserved
- `defaultHeaders`: Headers automatically added to every request
- `timeout`: Timeout in seconds (default: `100`)

The endpoint is appended directly to the base URL. For example, use
`baseUrl: 'http://localhost:8080'` with `endpoint: '/comments'`. Keep the slash
between them; it is not inserted or normalized automatically.

HTTP is supported without being upgraded to HTTPS. On mobile platforms, local
HTTP endpoints may require Android cleartext-traffic or iOS App Transport
Security configuration. Prefer HTTPS for production traffic.

### `request`

```dart
Future<HttpResponse> request({
	required HttpMethod method,
	String? endpoint,
	String? baseUrl,
	Map<String, dynamic>? fields,
	Map<String, dynamic>? queryParams,
	Map<String, String>? headers,
	Duration? timeout,
	List<RequestFile> requestFiles = const [],
	bool useFormData = false,
})
```

- `method`: HTTP method (`.get`, `.post`, `.put`, `.patch`, `.delete`)
- `endpoint`: Optional API route, for example `/comments`; omit it to use the base URL as-is
- `baseUrl`: Per-request full base URL override, including the scheme
- `fields`: JSON body fields (or multipart form fields)
- `queryParams`: URI-encoded query parameters merged with existing URL parameters;
  new values override matching keys. Values must be strings, iterables of
  strings, or `null` (convert numbers to strings first)
- `headers`: Per-request headers; when provided, these replace the configured defaults
- `timeout`: Per-request timeout override as a `Duration`
- `requestFiles`: Files for multipart requests (`RequestFileFromPath`,
  `RequestFileFromBytes`, `RequestFileFromString`)
- `useFormData`: Force multipart/form-data

## Response Shape

Requests return `HttpResponse` unless a timeout or unsupported request-file type
causes an exception:

```dart
class HttpResponse {
	final String? message;
	final ErrorType? errorType;
	final dynamic data;
	final bool success;
	final int? statusCode;
	final dynamic errorData;
}
```

`statusCode` is populated for successfully processed responses and handled HTTP
errors. It may be `null` for setup, network, timeout, or response-decoding failures.

`errorData` is declared `dynamic`. For handled HTTP errors, it is a named record
with `errorCode` and `errorData` fields. The payload is decoded JSON for handled
client errors and the raw response body for server errors. For network and other
client-side failures, it contains the caught exception instead. Responses
constructed by callers may use other `errorData` types.

Typical checks:

```dart
if (response.success) {
	// handle response.data
} else {
	// handle response.message
	print(response.errorType);
	print(response.statusCode);
	print(response.errorData);
}
```

Handle exceptions separately when making a request:

```dart
try {
	final response = await api.request(
		method: .get,
		endpoint: '/comments',
		timeout: const Duration(seconds: 10),
	);
	print(response.success);
} catch (error) {
	// Includes request timeouts and unsupported request-file types.
	print(error);
}
```

## Migrating To 2.0.0

- Include the scheme in every configured or per-request base URL. Bare hosts
  such as `example.com` must become `https://example.com` (or `http://` when
  explicitly needed). Existing `http://` URLs are no longer forced to HTTPS.
- Replace the removed `files` parameter with `requestFiles`:

  ```dart
  requestFiles: [
    RequestFileFromPath(itemKey: 'file', path: '/absolute/path/to/file.jpg'),
  ],
  ```

- `HttpResponse.errorData` is now `dynamic`. Use `statusCode` for HTTP status
  checks. HTTP failures return a named record, while network and other client-side
  failures expose the caught exception; do not assume every error is a record.
- Handle timeout and unsupported request-file exceptions with `try`/`catch`;
  these no longer return a failed `HttpResponse`.
- Upgrade to a Flutter SDK that includes Dart 3.13.4 or later.

## Notes

- `null` values in `fields` are automatically removed before sending.
- In multipart requests, `List` and `Map` values are encoded using bracketed
  form keys (for example: `items[0]`, `items[1]`, `meta[name]`) so backends like
  Laravel/PHP can parse them as arrays/objects.
- Explicit empty lists cannot be represented directly in multipart form fields.
  Empty lists are omitted; normalize them to `[]` on the server if needed.
- For multipart requests, avoid manually setting `content-type`; it is handled
  internally.
- Network errors return `success: false` with an `ErrorType`; `message` is
  optional and may be `null`. Request timeouts throw exceptions.
- For non-2xx responses, `success` is `false` and `errorData` contains server
  error details.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
