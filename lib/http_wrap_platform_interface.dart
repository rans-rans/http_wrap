import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'http_wrap_method_channel.dart';

abstract class HttpWrapPlatform extends PlatformInterface {
  /// Constructs the platform interface used by the generated plugin scaffold.
  HttpWrapPlatform() : super(token: _token);

  static final Object _token = Object();

  static HttpWrapPlatform _instance = MethodChannelHttpWrap();

  /// The active platform implementation for optional native integration.
  ///
  /// The main request API in this package runs directly in Dart. This interface
  /// remains available for the generated plugin wrapper and tests.
  static HttpWrapPlatform get instance => _instance;

  /// Registers a replacement platform implementation.
  static set instance(HttpWrapPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the host platform version from the example plugin channel.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
