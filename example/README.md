# http_wrap_example

Example app for `http_wrap`.

This example configures `HttpWrap` with the full base URL
`https://jsonplaceholder.typicode.com` and fetches comments using the package's
`request()` API.

## What It Shows

- Configuring a shared `HttpWrap` instance with `baseUrl`
- Sending a `GET` request with `queryParams`
- Filtering `/comments` by `postId` (defaults to `1`)
- Reading a top-level JSON array from `HttpResponse.data` and displaying each
  comment's ID, post ID, name, email, and body
- Handling loading, error, retry, and empty-result states
- Downloading files with progress, pause, resume, and cancel controls

The download example uses `/storage/emulated/0/Download/`, an Android-specific
path. Use a writable directory appropriate to your platform and handle any
required permissions before downloading.

## Running The Example

Use a Flutter SDK that includes Dart 3.13.4 or later. From the `example/`
directory, run:

```bash
flutter pub get
flutter run
```

Select **Http Request** to try the comments example. Enter a post ID and press
**Load Comments**; post `1` returns five comments.
