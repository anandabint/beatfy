import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;

import '../data/repositories/cloud_backup_repository.dart';
import '../models/cloud_backup_record.dart';
import '../models/song.dart';
import 'auth_service.dart';
import 'media_read_service.dart';

/// Upload/restore Google Drive (Architecture.md § 7, PRD.md § 7 poin 5).
/// Folder tujuan "Beatfy Backup" di root Drive user (bukan `appDataFolder`
/// tersembunyi — Pann bisa lihat langsung filenya via Drive app/browser).
class CloudBackupService {
  CloudBackupService({required CloudBackupRepository repository})
    : _repository = repository;

  final CloudBackupRepository _repository;

  static const _folderName = 'Beatfy Backup';
  static const _folderQuery =
      "name='$_folderName' and mimeType='application/vnd.google-apps.folder' "
      "and trashed=false and 'root' in parents";

  Future<drive.DriveApi> _driveApi() async {
    final client = await AuthService.getDriveAuthClient();
    return drive.DriveApi(client);
  }

  Future<String> _ensureBackupFolder(drive.DriveApi api) async {
    final cachedId = _repository.getMeta().driveFolderId;
    if (cachedId != null) return cachedId;

    final existing = await api.files.list(
      q: _folderQuery,
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    final found = existing.files;

    final String folderId;
    if (found != null && found.isNotEmpty) {
      folderId = found.first.id!;
    } else {
      final folder = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final created = await api.files.create(folder);
      folderId = created.id!;
    }

    await _repository.saveMeta(
      _repository.getMeta().copyWith(driveFolderId: folderId),
    );
    return folderId;
  }

  /// Upload semua [songs] yang belum ter-backup — tanpa record dianggap
  /// pending juga, bukan cuma yang eksplisit `BackupStatus.pending`
  /// (Architecture.md § 7). Gagal di satu lagu tidak menghentikan lagu
  /// lain — ditandai `failed` + `lastAttemptAt`, dicoba lagi trigger WiFi
  /// berikutnya (bukan retry loop langsung).
  Future<void> uploadPending(List<Song> songs) async {
    if (!_repository.getMeta().autoBackupEnabled) {
      debugPrint('[CloudBackup] uploadPending: auto-backup disabled, skip');
      return;
    }

    final drive.DriveApi api;
    try {
      api = await _driveApi();
    } on Object catch (e) {
      debugPrint('[CloudBackup] uploadPending: drive auth failed, abort: $e');
      return;
    }

    final folderId = await _ensureBackupFolder(api);
    debugPrint('[CloudBackup] "Beatfy Backup" folder id=$folderId');

    var pendingCount = 0;
    var doneCount = 0;
    var failedCount = 0;
    for (final song in songs) {
      final record = _repository.getRecord(song.id);
      if (record?.backupStatus == BackupStatus.done) continue;
      pendingCount++;

      await _repository.saveRecord(
        CloudBackupRecord(
          songId: song.id,
          backupStatus: BackupStatus.uploading,
        ),
      );
      debugPrint('[CloudBackup] uploading id=${song.id} "${song.title}"');
      try {
        final bytes = await MediaReadService.readBytes(song.filePath);
        final fileName = song.dataPath != null
            ? p.basename(song.dataPath!)
            : '${song.title} - ${song.artist}.mp3';

        final driveFile = drive.File()
          ..name = fileName
          ..parents = [folderId];
        final uploaded = await api.files.create(
          driveFile,
          uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
        );

        await _repository.saveRecord(
          CloudBackupRecord(
            songId: song.id,
            driveFileId: uploaded.id,
            backupStatus: BackupStatus.done,
          ),
        );
        doneCount++;
        debugPrint('[CloudBackup] uploaded id=${song.id} fileId=${uploaded.id}');
      } on Object catch (e) {
        failedCount++;
        debugPrint('[CloudBackup] upload FAILED id=${song.id} "${song.title}": $e');
        await _repository.saveRecord(
          CloudBackupRecord(
            songId: song.id,
            backupStatus: BackupStatus.failed,
            lastAttemptAt: DateTime.now(),
          ),
        );
      }
    }
    debugPrint(
      '[CloudBackup] uploadPending done: $pendingCount queued, '
      '$doneCount uploaded, $failedCount failed (of ${songs.length} total songs)',
    );
  }

  /// File di folder "Beatfy Backup" — dipakai restore gate + Restore screen.
  /// Null kalau folder belum pernah dibuat sama sekali (akun belum pernah
  /// backup) — caller wajib skip restore screen di kasus ini, bukan
  /// menampilkan progress kosong (PRD.md § 7 poin 5).
  Future<List<drive.File>?> restoreCandidates() async {
    final drive.DriveApi api;
    try {
      api = await _driveApi();
    } on Object {
      return null;
    }

    final existing = await api.files.list(
      q: _folderQuery,
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    final folders = existing.files;
    if (folders == null || folders.isEmpty) return null;
    final folderId = folders.first.id!;

    final contents = await api.files.list(
      q: "'$folderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name,mimeType)',
    );
    return contents.files ?? const [];
  }

  Future<Uint8List> downloadFile(String fileId) async {
    final api = await _driveApi();
    final response = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
    final media = response as drive.Media;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.toBytes();
  }
}
