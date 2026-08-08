import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../data/repositories/cloud_backup_repository.dart';
import '../models/cloud_backup_record.dart';
import '../services/cloud_backup_service.dart';
import 'auth_providers.dart';
import 'library_providers.dart';

/// Status backup per lagu — dipakai ikon kecil di song row (Architecture.md
/// § 7b). Null berarti belum pernah ada percobaan backup sama sekali.
final backupStatusProvider = Provider.family<BackupStatus?, int>((
  ref,
  songId,
) {
  return ref.watch(cloudBackupRepositoryProvider).getRecord(songId)?.backupStatus;
});

final cloudBackupRepositoryProvider = Provider<CloudBackupRepository>((ref) {
  throw UnimplementedError(
    'cloudBackupRepositoryProvider must be overridden in main()',
  );
});

final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  return CloudBackupService(
    repository: ref.watch(cloudBackupRepositoryProvider),
  );
});

/// Backup manual — tombol "Backup Sekarang" di Settings screen (Design.md
/// § 7). Revisi 2026-08-07: trigger otomatis lewat listener konektivitas
/// (`ConnectivityBackupNotifier`, coba cek WiFi di cold start) sempat
/// dicoba lagi supaya auto-backup benar-benar jalan tanpa perlu toggle
/// WiFi manual — tapi QC di device nyata Pann (2 akun Google) membuktikan
/// popup "Choose an account" muncul di **setiap** cold start selagi WiFi
/// nyala, bukan cuma sesekali/gara-gara race (satu panggilan tunggal pun
/// tetap memicunya). Ini UI asli Android (Credential Manager), bukan bisa
/// disembunyikan dari kode app. Diputuskan bareng Pann: ganti ke tombol
/// eksplisit — popup akun (kalau device-nya memang perlu) jadi terasa
/// wajar sebagai kelanjutan tap user, bukan interupsi random pas buka
/// Home. `AuthService.getDriveAuthClient`'s mutex tetap dipertahankan
/// (masih berguna kalau `RestoreGateNotifier` kebetulan jalan bersamaan).
class ManualBackupNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> backupNow() async {
    if (state.isLoading) return;

    if (ref.read(userProfileRepositoryProvider).get() == null) {
      state = AsyncValue.error(
        'Belum sign-in Google.',
        StackTrace.current,
      );
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.wifi)) {
      debugPrint('[CloudBackup] manual backup skipped: no WiFi');
      state = AsyncValue.error(
        'Sambungkan ke WiFi dulu untuk backup.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    debugPrint('[CloudBackup] manual backup starting');
    try {
      final songs = await ref.read(librarySongsProvider.future);
      debugPrint('[CloudBackup] manual backup: ${songs.length} songs in library');
      await ref.read(cloudBackupServiceProvider).uploadPending(songs);
      debugPrint('[CloudBackup] manual backup finished');
      state = const AsyncValue.data(null);
    } on Object catch (e, st) {
      debugPrint('[CloudBackup] manual backup threw: $e\n$st');
      state = AsyncValue.error(e, st);
    } finally {
      ref.invalidate(backupSummaryProvider);
      ref.invalidate(backupStatusProvider);
    }
  }
}

final manualBackupProvider =
    NotifierProvider<ManualBackupNotifier, AsyncValue<void>>(
      ManualBackupNotifier.new,
    );

/// Toggle backup ke Google Drive — Settings screen (Design.md § 7). Sejak
/// pindah ke tombol manual (2026-08-07), ini jadi master on/off untuk
/// fitur backup-nya (bukan lagi soal "otomatis") — kalau `false`, tombol
/// "Backup Sekarang" disembunyikan/dinonaktifkan.
class AutoBackupToggleNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(cloudBackupRepositoryProvider).getMeta().autoBackupEnabled;

  Future<void> toggle(bool enabled) async {
    final repository = ref.read(cloudBackupRepositoryProvider);
    await repository.saveMeta(
      repository.getMeta().copyWith(autoBackupEnabled: enabled),
    );
    state = enabled;
  }
}

final autoBackupEnabledProvider =
    NotifierProvider<AutoBackupToggleNotifier, bool>(
      AutoBackupToggleNotifier.new,
    );

/// "X dari Y lagu ter-backup" — Settings screen (Design.md § 7).
final backupSummaryProvider = Provider<({int done, int total})>((ref) {
  final repository = ref.watch(cloudBackupRepositoryProvider);
  final songsAsync = ref.watch(librarySongsProvider);
  final total = songsAsync.value?.length ?? 0;
  return (done: repository.doneCount(), total: total);
});

class RestoreGateState {
  const RestoreGateState({required this.needsRestore, this.files = const []});

  final bool needsRestore;
  final List<drive.File> files;
}

/// Dicek sekali di app start (PRD.md § 7 poin 5): `songs` box kosong + user
/// sign-in + folder "Beatfy Backup" ada isinya → `RestoreScreen`. Kalau
/// user sign-in tapi belum pernah backup (folder tidak ada/kosong), skip
/// langsung ke app normal — bukan alasan buat gagal cold-start.
class RestoreGateNotifier extends AsyncNotifier<RestoreGateState> {
  @override
  Future<RestoreGateState> build() async {
    final repository = ref.watch(libraryRepositoryProvider);
    if (repository.getCachedSongs().isNotEmpty) {
      return const RestoreGateState(needsRestore: false);
    }

    final profile = await ref.watch(userProfileProvider.future);
    if (profile == null) {
      return const RestoreGateState(needsRestore: false);
    }

    final service = ref.read(cloudBackupServiceProvider);
    List<drive.File>? files;
    try {
      files = await service.restoreCandidates();
    } on Object {
      files = null;
    }
    if (files == null || files.isEmpty) {
      return const RestoreGateState(needsRestore: false);
    }
    return RestoreGateState(needsRestore: true, files: files);
  }
}

final restoreGateProvider =
    AsyncNotifierProvider<RestoreGateNotifier, RestoreGateState>(
      RestoreGateNotifier.new,
    );
