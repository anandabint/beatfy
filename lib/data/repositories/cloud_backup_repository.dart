import 'package:hive_ce/hive_ce.dart';

import '../../models/cloud_backup_meta.dart';
import '../../models/cloud_backup_record.dart';
import '../local/hive/hive_setup.dart';

/// Akses Hive buat status backup Drive per lagu + metadata folder/toggle 
/// Schema.md § 3. UI/service tidak pernah baca box `cloud_backup*` langsung.
class CloudBackupRepository {
  CloudBackupRepository({
    Box<CloudBackupRecord>? recordsBox,
    Box<CloudBackupMeta>? metaBox,
  }) : _recordsBox =
           recordsBox ?? Hive.box<CloudBackupRecord>(HiveBoxes.cloudBackup),
       _metaBox =
           metaBox ?? Hive.box<CloudBackupMeta>(HiveBoxes.cloudBackupMeta);

  static const _metaKey = 'current';

  final Box<CloudBackupRecord> _recordsBox;
  final Box<CloudBackupMeta> _metaBox;

  CloudBackupRecord? getRecord(int songId) => _recordsBox.get(songId);

  List<CloudBackupRecord> allRecords() => _recordsBox.values.toList();

  Future<void> saveRecord(CloudBackupRecord record) =>
      _recordsBox.put(record.songId, record);

  /// Dipakai saat lagu dihapus dari device (Architecture.md § 4a)  bersihkan
  /// juga entry backup-nya, konsisten dengan repository lain.
  Future<void> removeRecord(int songId) async {
    if (_recordsBox.containsKey(songId)) await _recordsBox.delete(songId);
  }

  int doneCount() => _recordsBox.values
      .where((record) => record.backupStatus == BackupStatus.done)
      .length;

  CloudBackupMeta getMeta() => _metaBox.get(_metaKey) ?? CloudBackupMeta();

  Future<void> saveMeta(CloudBackupMeta meta) => _metaBox.put(_metaKey, meta);
}
