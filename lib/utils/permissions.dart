// lib/utils/permissions.dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureLocationAndCamera() async {
  final loc = await Permission.location.request();
  final cam = await Permission.camera.request();
  return loc.isGranted && cam.isGranted;
}
