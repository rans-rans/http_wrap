# http_wrap

A lightweight Dart/Flutter wrapper around the `http` package to make API calls simpler.

Set your request values (`body`, `headers`, `params`, files, etc.) and call one method.

## API

### `config`

```dart
void config({
	String? baseUrl,
	Map<String, String>? defaultHeaders,
	int? timeout,
})
```

- `baseUrl`: Default host/base URL used when calling `request`
- `defaultHeaders`: Headers automatically added to every request
- `timeout`: Timeout in seconds (default: `100`)

### `request`

```dart
Future<HttpResponse> request({
	required HttpMethod method,
	required String endpoint,
	String? baseUrl,
	Map<String, dynamic>? fields,
	Map<String, dynamic>? queryParams,
	Map<String, String>? headers,
	List<({String key, String? path})> files = const [],
	bool useFormData = false,
})
```

- `method`: HTTP method (`.get`, `.post`, `.put`, `.patch`, `.delete`)
- `endpoint`: API route, example: `/api/v2/books`
- `baseUrl`: Per-request base URL override
- `fields`: JSON body fields (or multipart form fields)
- `queryParams`: URL query parameters
- `headers`: Per-request headers
- `files`: Files for multipart requests `(key, path)`
- `useFormData`: Force multipart/form-data

## Response Shape

Every request returns `HttpResponse`:

```dart
class HttpResponse {
	final String? message;
	final dynamic data;
	final bool success;
	final ({int? errorCode, dynamic errorData})? errorData;
}
```

Typical checks:

```dart
if (response.success) {
	// handle response.data
} else {
	// handle response.message
	print(response.errorData?.errorCode);
	print(response.errorData?.errorData);
}
```

## Features

- Simple, single entry-point request API
- Base URL and default header configuration
- Query params support
- JSON request body support
- Multipart/form-data support for file uploads
- Unified response object (`HttpResponse`)
- Structured error metadata (`errorCode`, `errorData`) for failed requests
- Basic timeout and network error handling

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
	http_wrap: ^1.0.0
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
		baseUrl: 'https://fakerapi.it',
		defaultHeaders: {
			'Content-Type': 'application/json',
			'Accept': 'application/json',
		},
		timeout: 30,
	);
```

### GET Request With Query Params

```dart
final res = await api.request(
	method: .get,
	endpoint: '/api/v2/books',
	queryParams: {
		'_quantity': '5',
		'_locale': 'en_US',
	},
);

if (res.success) {
	print(res.data);
} else {
	print(res.message);
}
```

### POST Request With JSON Body

```dart
final res = await api.request(
	method: .post,
	endpoint: '/api/v1/users',
	fields: {
		'name': 'John Doe',
		'email': 'john@acme.com',
	},
	headers: {
		'Authorization': 'Bearer your_token_here',
	},
);
```

### Multipart/Form-Data Request (File Upload)

```dart
final res = await api.request(
	method: .post,
	endpoint: '/api/v1/upload',
	useFormData: true,
	fields: {
		'title': 'Profile photo',
	},
	files: [
		(key: 'file', path: '/absolute/path/to/image.jpg'),
	],
);
```

## Notes

- `null` values in `fields` are automatically removed before sending.
- For multipart requests, avoid manually setting `content-type`; it is handled internally.
- Network and timeout errors are converted to readable `message` values.
- For non-2xx responses, `success` is `false` and `errorData` contains server error details.

## License

This project is licensed under the MIT License. See `LICENSE` for details.

