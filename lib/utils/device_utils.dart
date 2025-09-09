import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:device_info_plus/device_info_plus.dart';
import 'package:universal_io/io.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:html' as html;

Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();

  if (kIsWeb) {
    // Web: Try geolocation first
     try {
    if (kIsWeb) {
      // 🔹 First try GPS
      try {
        final pos = await Geolocator.getCurrentPosition();
        if (pos.latitude != null && pos.longitude != null) {
          return "web-${pos.latitude},${pos.longitude}";
        }
      } catch (e) {
        print("⚠️ Web GPS failed: $e");
      }

      // 🔹 Fallback: browser fingerprint
      return "browser-${html.window.navigator.userAgent}";
    } else if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return info.id ?? '${info.device}-${info.version.sdkInt}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.identifierForVendor ??
          info.utsname.machine ??
          'ios-${DateTime.now().millisecondsSinceEpoch}';
    } else {
      return "unknown-device";
    }
  } catch (e) {
    return "error-$e";
  }

    // Fallback → browser/device info
    final info = await deviceInfo.webBrowserInfo;
    return "${info.browserName.name}-${info.userAgent ?? "unknown_web"}";
  }

  // ✅ Native apps
  if (Platform.isAndroid) {
    final info = await deviceInfo.androidInfo;
    return info.id ?? '${info.device ?? ''}-${info.version.sdkInt}';
  } else if (Platform.isIOS) {
    final info = await deviceInfo.iosInfo;
    return info.identifierForVendor ??
        info.utsname.machine ??
        'ios-${DateTime.now().millisecondsSinceEpoch}';
  } else {
    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }
}
