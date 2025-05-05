import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_liveness_detection_randomized_plugin/flutter_liveness_detection_randomized_plugin.dart';
import 'package:flutter_liveness_detection_randomized_plugin/flutter_liveness_detection_randomized_plugin_platform_interface.dart';
import 'package:flutter_liveness_detection_randomized_plugin/flutter_liveness_detection_randomized_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterLivenessDetectionRandomizedPluginPlatform
    with MockPlatformInterfaceMixin
    implements FlutterLivenessDetectionRandomizedPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterLivenessDetectionRandomizedPluginPlatform initialPlatform = FlutterLivenessDetectionRandomizedPluginPlatform.instance;

  test('$MethodChannelFlutterLivenessDetectionRandomizedPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterLivenessDetectionRandomizedPlugin>());
  });

  test('getPlatformVersion', () async {
    FlutterLivenessDetectionRandomizedPlugin flutterLivenessDetectionRandomizedPlugin = FlutterLivenessDetectionRandomizedPlugin.instance;
    MockFlutterLivenessDetectionRandomizedPluginPlatform fakePlatform = MockFlutterLivenessDetectionRandomizedPluginPlatform();
    FlutterLivenessDetectionRandomizedPluginPlatform.instance = fakePlatform;

    expect(await flutterLivenessDetectionRandomizedPlugin.getPlatformVersion(), '42');
  });
}
