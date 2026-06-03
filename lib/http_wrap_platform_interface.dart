import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'http_wrap_method_channel.dart';

abstract class HttpWrapPlatform extends PlatformInterface {
  /// Constructs a HttpWrapPlatform.
  HttpWrapPlatform() : super(token: _token);

  static final Object _token = Object();

  static HttpWrapPlatform _instance = MethodChannelHttpWrap();

  /// The default instance of [HttpWrapPlatform] to use.
  ///
  /// Defaults to [MethodChannelHttpWrap].
  static HttpWrapPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HttpWrapPlatform] when
  /// they register themselves.
  static set instance(HttpWrapPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
