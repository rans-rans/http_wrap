import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http_wrap/http_wrap.dart';

void main() {
  group('HttpWrap.request', () {
    final api = HttpWrap();
    const comments = [
      {
        'postId': 1,
        'id': 1,
        'name': 'Sample comment',
        'email': 'comment@example.com',
        'body': 'A comment body.',
      },
    ];
    const errorPayload = {'message': 'Example error'};

    late HttpServer server;
    late String baseUrl;
    Uri? requestedUri;

    setUp(() async {
      requestedUri = null;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUrl = 'http://${server.address.address}:${server.port}';
      api.config(baseUrl: baseUrl, defaultHeaders: const {}, timeout: 5);

      server.listen((request) async {
        requestedUri = request.uri;
        if (request.uri.path == '/timeout') return;

        final statusCode = switch (request.uri.path) {
          '/client-error' => HttpStatus.badRequest,
          '/server-error' => HttpStatus.serviceUnavailable,
          _ => HttpStatus.ok,
        };
        request.response
          ..statusCode = statusCode
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(statusCode == HttpStatus.ok ? comments : errorPayload),
          );
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('preserves HTTP and decodes a top-level comments array', () async {
      final response = await api.request(method: .get, endpoint: '/comments');

      expect(response.success, isTrue);
      expect(response.statusCode, HttpStatus.ok);
      expect(response.errorType, isNull);
      expect(response.data, comments);
      expect(requestedUri?.path, '/comments');
      expect(requestedUri?.hasQuery, isFalse);
    });

    test('allows a full per-request base URL override', () async {
      api.config(baseUrl: 'https://unused.invalid');

      final response = await api.request(
        method: .get,
        baseUrl: baseUrl,
        endpoint: '/comments',
      );

      expect(response.success, isTrue);
      expect(requestedUri?.path, '/comments');
    });

    test('uses the full base URL when endpoint is omitted', () async {
      final response = await api.request(
        method: .get,
        baseUrl: '$baseUrl/comments?postId=1',
      );

      expect(response.success, isTrue);
      expect(requestedUri?.path, '/comments');
      expect(requestedUri?.queryParameters, {'postId': '1'});
    });

    test(
      'encodes query keys and values without changing their meaning',
      () async {
        const key = 'search & term';
        const value = 'a&b = + # ? % café/✓';

        final response = await api.request(
          method: .get,
          endpoint: '/comments',
          queryParams: {key: value},
        );

        expect(response.success, isTrue);
        expect(requestedUri?.queryParameters, {key: value});
      },
    );

    test(
      'merges queries and preserves unrelated repeated parameters',
      () async {
        final response = await api.request(
          method: .get,
          endpoint: '/comments?postId=2&tag=one&tag=two&keep=value',
          queryParams: {'postId': '1'},
        );

        expect(response.success, isTrue);
        expect(requestedUri?.queryParametersAll, {
          'postId': ['1'],
          'tag': ['one', 'two'],
          'keep': ['value'],
        });
      },
    );

    test('keeps an existing query when queryParams is empty', () async {
      const endpoint = '/comments?postId=1&tag=one&tag=two';
      final response = await api.request(
        method: .get,
        endpoint: endpoint,
        queryParams: const {},
      );

      expect(response.success, isTrue);
      expect(requestedUri.toString(), endpoint);
    });

    test('supports iterable and null query values', () async {
      final response = await api.request(
        method: .get,
        endpoint: '/comments',
        queryParams: {
          'tag': ['a&b', 'c d'],
          'flag': null,
        },
      );

      expect(response.success, isTrue);
      expect(requestedUri?.queryParametersAll, {
        'tag': ['a&b', 'c d'],
        'flag': [''],
      });
    });

    test(
      'returns the status code and error record for client errors',
      () async {
        final response = await api.request(
          method: .get,
          endpoint: '/client-error',
        );

        expect(response.success, isFalse);
        expect(response.statusCode, HttpStatus.badRequest);
        expect(response.errorType, ErrorType.status400);
        expect(response.data, errorPayload);
        final details =
            response.errorData as ({int? errorCode, dynamic errorData});
        expect(details.errorCode, HttpStatus.badRequest);
        expect(details.errorData, errorPayload);
      },
    );

    test('returns the status code and raw body for server errors', () async {
      final response = await api.request(
        method: .get,
        endpoint: '/server-error',
      );

      expect(response.success, isFalse);
      expect(response.statusCode, HttpStatus.serviceUnavailable);
      expect(response.errorType, ErrorType.status500);
      expect(response.data, isNull);
      final details =
          response.errorData as ({int? errorCode, dynamic errorData});
      expect(details.errorCode, HttpStatus.serviceUnavailable);
      expect(details.errorData, jsonEncode(errorPayload));
    });

    test('keeps the caught exception for an invalid URL', () async {
      final response = await api.request(method: .get, baseUrl: 'http://[');

      expect(response.success, isFalse);
      expect(response.statusCode, isNull);
      expect(response.errorType, ErrorType.unknown);
      expect(response.errorData, isA<FormatException>());
    });

    test('propagates request timeout exceptions', () async {
      await expectLater(
        api.request(
          method: .get,
          endpoint: '/timeout',
          timeout: const Duration(milliseconds: 20),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Request timed out'),
          ),
        ),
      );
    });
  });
}
