// import 'package:flutter_test/flutter_test.dart';
// import 'package:http_wrap/http_wrap.dart';
// import 'package:http_wrap/http_wrap_platform_interface.dart';
// import 'package:http_wrap/http_wrap_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockHttpWrapPlatform
//     with MockPlatformInterfaceMixin
//     implements HttpWrapPlatform {
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final HttpWrapPlatform initialPlatform = HttpWrapPlatform.instance;

//   test('$MethodChannelHttpWrap is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelHttpWrap>());
//   });

//   test('getPlatformVersion', () async {
//     HttpWrap httpWrapPlugin = HttpWrap();
//     MockHttpWrapPlatform fakePlatform = MockHttpWrapPlatform();
//     HttpWrapPlatform.instance = fakePlatform;

//     expect(await httpWrapPlugin.getPlatformVersion(), '42');
//   });
// }
