import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../providers/cloud_backup_providers.dart';
import '../../providers/library_providers.dart';
import '../../services/media_insert_service.dart';

/// Full-screen, tidak bisa di-skip — muncul sekali di device baru saat
/// `songs` box kosong tapi akun Drive punya folder backup berisi file
/// (PRD.md § 7 poin 5, Design.md § 7 "Restore screen"). Download semua file
/// lalu jalankan scan lokal biasa supaya masuk `songs` box seperti lagu
/// biasa (Schema.md § 5 — file ditulis ke koleksi Audio publik, bukan
/// app-private, justru supaya scan biasa ini bisa menemukannya).
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key, required this.files});

  final List<drive.File> files;

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  int _downloaded = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    final service = ref.read(cloudBackupServiceProvider);

    for (final file in widget.files) {
      final fileId = file.id;
      final name = file.name;
      if (fileId == null || name == null) continue;
      try {
        final bytes = await service.downloadFile(fileId);
        await MediaInsertService.insertAudioFile(
          displayName: name,
          bytes: bytes,
          mimeType: file.mimeType ?? 'audio/mpeg',
        );
      } on Object {
        // Lanjut ke file berikutnya — satu file gagal tidak boleh
        // menghentikan restore file lain (PRD.md § 7 poin 5 tidak
        // menyebutkan retry di sini; user bisa retry manual lain waktu
        // lewat re-scan/backup ulang).
      }
      if (!mounted) return;
      setState(() => _downloaded++);
    }

    try {
      await ref.read(librarySongsProvider.notifier).rescan();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal scan library: $error');
      return;
    }

    // `songs` box sekarang tidak kosong lagi — invalidate supaya
    // `restoreGateProvider` re-evaluasi dan `_RootGate` (app.dart) pindah
    // ke `MainShell` secara reaktif, tanpa navigasi manual di sini.
    ref.invalidate(restoreGateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.files.length;
    final progress = total == 0 ? 0.0 : _downloaded / total;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_download_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Memulihkan lagu dari Google Drive',
                  textAlign: TextAlign.center,
                  style: AppTextTheme.titleMedium.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$_downloaded/$total file terdownload',
                  style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceMuted,
                    color: AppColors.primary,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTextTheme.bodySmall.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
