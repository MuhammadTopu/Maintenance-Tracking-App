import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:permission_handler/permission_handler.dart';

import 'logger.dart';

class ImageHelper {
  static const _limit = 5 * 1024 * 1024; // 5MB
  static final _picker = ImagePicker();

  /// Handles permission -> pick/capture -> fit under 5 MB.
  /// Returns null if cancelled, denied or failed.
  static Future<File?> pick(BuildContext context, ImageSource source) async {
    final bool granted;
    if (source == ImageSource.camera) {
      granted = await _ensure(context, Permission.camera, 'Camera');
    } else if (Platform.isIOS) {
      granted = await _ensure(context, Permission.photos, 'Photo library');
    } else {
      granted = true;
    }
    if (!granted) return null;

    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return null;
      return await _fit(File(picked.path));
    } catch (e) {
      Log.debug('pick failed: $e');
      AppToast.showToast('Could not use this image');
      return null;
    }
  }

  static Future<bool> _ensure(
      BuildContext context,
      Permission permission,
      String label,
      ) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    if (!context.mounted) return false;

    if (status.isPermanentlyDenied || status.isRestricted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$label permission needed'),
          content: Text('Please allow $label access in Settings to use this.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (open == true) await openAppSettings();
    } else {
      AppToast.showToast('$label permission denied');
    }
    return false;
  }

  static Future<File> _fit(File f) async {
    if (await f.length() <= _limit) return f;
    var size = 2000, q = 90;
    while (size >= 400) {
      final out = await FlutterImageCompress.compressAndGetFile(
        f.path,
        '${f.path}_$size$q.jpg',
        quality: q,
        minWidth: size,
        minHeight: size,
      );
      if (out != null && await out.length() <= _limit) return File(out.path);
      if (q > 50) {
        q -= 10;
      } else {
        size = (size * .75).round();
        q = 80;
      }
    }
    throw Exception('Image too large');
  }
}