// lib/utils/device_utils.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final info = await deviceInfo.androidInfo;
    return info.id ?? '${info.device ?? ''}-${info.version.sdkInt}';
  } else {
    final info = await deviceInfo.iosInfo;
    return info.identifierForVendor ?? info.utsname.machine ?? 'ios-${DateTime.now().millisecondsSinceEpoch}';
  }
}
