import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> checkAllPermissions() async {
    if (Platform.isAndroid) {
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;
      final screenSharingStatus = await Permission.systemAlertWindow.status;

      return cameraStatus.isGranted &&
          microphoneStatus.isGranted &&
          screenSharingStatus.isGranted;
    } else {
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;

      return cameraStatus.isGranted && microphoneStatus.isGranted;
    }
  }

  static Future<bool> requestAllPermissions() async {
    if (Platform.isAndroid) {
      final permissions = await [
        Permission.camera,
        Permission.microphone,
        Permission.systemAlertWindow,
      ].request();

      final cameraStatus = permissions[Permission.camera];
      final microphoneStatus = permissions[Permission.microphone];
      final screenSharingStatus = permissions[Permission.systemAlertWindow];

      return cameraStatus?.isGranted == true &&
          microphoneStatus?.isGranted == true &&
          screenSharingStatus?.isGranted == true;
    } else {
      final permissions = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraStatus = permissions[Permission.camera];
      final microphoneStatus = permissions[Permission.microphone];

      return cameraStatus?.isGranted == true &&
          microphoneStatus?.isGranted == true;
    }
  }

  static Future<bool> requestScreenSharingPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.systemAlertWindow.isGranted) {
        return true;
      }

      final status = await Permission.systemAlertWindow.request();
      return status.isGranted;
    } else {
      return true;
    }
  }

  static Future<Map<String, bool>> getPermissionStatus() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    final result = {
      'camera': cameraStatus.isGranted,
      'microphone': microphoneStatus.isGranted,
    };

    if (Platform.isAndroid) {
      final screenSharingStatus = await Permission.systemAlertWindow.status;
      result['screenSharing'] = screenSharingStatus.isGranted;
    } else {
      result['screenSharing'] = true;
    }

    return result;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
