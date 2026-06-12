import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'http_wrap_platform_interface.dart';

/// Default method-channel implementation kept for plugin scaffold parity.
class MethodChannelHttpWrap extends HttpWrapPlatform {
  /// Channel used by the generated example/platform-version integration.
  @visibleForTesting
  final methodChannel = const MethodChannel('http_wrap');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
