import 'package:permission_handler/permission_handler.dart';

enum LibraryPermissionStatus { granted, denied, permanentlyDenied }

/// Runtime permission untuk akses library audio (PRD.md § 6.9, Rules.md § 7).
///
/// Android 13+ pakai `READ_MEDIA_AUDIO` (`Permission.audio`); di bawahnya
/// (termasuk device test Android 12) pakai `READ_EXTERNAL_STORAGE`
/// (`Permission.storage`)  `Permission.audio` tidak pernah ter-grant di
/// bawah API 33, jadi keduanya dicek/diminta bersamaan. `permission_handler`
/// otomatis no-op untuk grup yang tidak berlaku di versi Android yang sedang
/// jalan (tidak ada permission name di manifest untuk grup itu), jadi tidak
/// muncul dialog ganda ke user.
abstract final class PermissionService {
  static const _permissions = [Permission.audio, Permission.storage];

  static Future<LibraryPermissionStatus> checkStatus() async {
    final statuses = await Future.wait(_permissions.map((p) => p.status));
    return _combine(statuses);
  }

  static Future<LibraryPermissionStatus> request() async {
    final results = await _permissions.request();
    return _combine(results.values.toList());
  }

  static Future<bool> openSettings() => openAppSettings();

  static LibraryPermissionStatus _combine(List<PermissionStatus> statuses) {
    if (statuses.any((s) => s.isGranted || s.isLimited)) {
      return LibraryPermissionStatus.granted;
    }
    if (statuses.any((s) => s.isPermanentlyDenied)) {
      return LibraryPermissionStatus.permanentlyDenied;
    }
    return LibraryPermissionStatus.denied;
  }
}
