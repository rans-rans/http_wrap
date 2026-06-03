import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'http_wrap_platform_interface.dart';

/// An implementation of [HttpWrapPlatform] that uses method channels.
class MethodChannelHttpWrap extends HttpWrapPlatform {
  /// The method channel used to interact with the native platform.
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
