import 'package:flutter_test/flutter_test.dart';
import 'package:http_wrap/http_wrap.dart';

void main() {
  test('HttpWrap returns the shared instance', () {
    expect(identical(HttpWrap(), HttpWrap()), isTrue);
  });

  test(
    'HttpResponse defaults to an unsuccessful response without metadata',
    () {
      const response = HttpResponse(errorType: .invalidSetup, data: null);

      expect(response.success, isFalse);
      expect(response.errorType, ErrorType.invalidSetup);
      expect(response.message, isNull);
      expect(response.statusCode, isNull);
      expect(response.errorData, isNull);
    },
  );

  test('HttpResponse accepts custom error payloads', () {
    const response = HttpResponse(
      errorType: .status400,
      data: null,
      statusCode: 400,
      errorData: {'message': 'Custom error'},
    );

    expect(response.statusCode, 400);
    expect(response.errorData, {'message': 'Custom error'});
  });
}
