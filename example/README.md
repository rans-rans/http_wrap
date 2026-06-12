# http_wrap_example

Example app for `http_wrap`.

This example configures `HttpWrap` with a base URL and fetches book data from
`https://fakerapi.it` using the package's `request()` API.

## What It Shows

- Configuring a shared `HttpWrap` instance with `baseUrl`
- Sending a `GET` request with `queryParams`
- Reading the normalized `HttpResponse` payload in a Flutter UI

## Running The Example

```bash
flutter pub get
flutter run
```
