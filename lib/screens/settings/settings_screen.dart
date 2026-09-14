import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/user_profile.dart';
import '../../providers/audio_enhancement_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/cloud_backup_providers.dart';
import '../../widgets/common/user_avatar.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// Entry point cloud backup  diakses dari tap avatar di header Home
/// (PRD.md § 7 poin 5, bukan tab bottom nav terpisah). Flat dark, tanpa
/// gradient blob (Design.md § 7  konsisten Library/Search).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final signedIn = profile != null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTextTheme.displayLarge.copyWith(color: AppColors.ink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        children: [
          _AccountSection(profile: profile, signedIn: signedIn),
          const SizedBox(height: AppSpacing.xl),
          if (signedIn) ...[
            const _AutoBackupToggle(),
            const SizedBox(height: AppSpacing.md),
            const _BackupSummary(),
            const SizedBox(height: AppSpacing.sm),
            const _ManualBackupButton(),
            const SizedBox(height: AppSpacing.xl),
            const _SignOutButton(),
          ],
          const SizedBox(height: AppSpacing.xl),
          const _AudioEnhancementSection(),
          const SizedBox(height: AppSpacing.xl),
          const _AboutSection(),
        ],
      ),
    );
  }
}

/// Section "Tentang"  PRD.md § 7 poin 10, Design.md § 7 row "Section
/// 'Tentang' (Settings)". List item sederhana (icon kiri + label + chevron
/// kanan), bukan card besar, biar tetap terasa ringkas/minimalist.
class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(_packageInfoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            'Tentang',
            style: AppTextTheme.labelMedium.copyWith(color: AppColors.ash),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        packageInfo.when(
          data: (info) => _AppInfoRow(info: info),
          loading: () => const _AppInfoRow(info: null),
          error: (_, _) => const _AppInfoRow(info: null),
        ),
        const _InfoRow(
          icon: Icons.person_outline,
          label: 'Developer',
          value: 'Ananda Bintang Ramadhan',
        ),
        _ActionRow(
          icon: Icons.mail_outline,
          label: 'Laporkan Bug / Masukan',
          onTap: () => _reportBug(context),
        ),
        _ActionRow(
          icon: Icons.privacy_tip_outlined,
          label: 'Privasi',
          onTap: () => _showPrivacySheet(context),
        ),
        _ActionRow(
          icon: Icons.description_outlined,
          label: 'Lisensi Open Source',
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Beatfy',
            applicationVersion: packageInfo.value?.version,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            'Beatfy dirilis di bawah GNU General Public License v3 (GPLv3).',
            style: AppTextTheme.bodySmall.copyWith(color: AppColors.stone),
          ),
        ),
      ],
    );
  }

  Future<void> _reportBug(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'anandabramadhan@gmail.com',
      query: 'subject=Beatfy%20-%20Feedback',
    );
    final launched =
        await canLaunchUrl(uri) && await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada aplikasi email terpasang.',
            style: AppTextTheme.bodySmall.copyWith(color: AppColors.ink),
          ),
          backgroundColor: AppColors.surfaceHover,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privasi',
              style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Beatfy tidak mengumpulkan data pengguna, tidak ada iklan '
              'atau analytics pihak ketiga. Satu-satunya data yang keluar '
              'dari perangkat adalah file musik yang di-backup ke Google '
              'Drive akun kamu sendiri, hanya kalau fitur backup '
              'diaktifkan  Beatfy tidak punya server sendiri yang '
              'menyimpan data apapun.',
              style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ash),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppInfoRow extends StatelessWidget {
  const _AppInfoRow({required this.info});

  final PackageInfo? info;

  @override
  Widget build(BuildContext context) {
    final versionText = info == null
        ? ''
        : 'v${info!.version} (${info!.buildNumber})';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.music_note_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Beatfy',
              style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
            ),
          ),
          Text(
            versionText,
            style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ash, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
            ),
          ),
          Text(
            value,
            style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, color: AppColors.ash, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.stone,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.profile, required this.signedIn});

  final UserProfileCache? profile;
  final bool signedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const UserAvatar(size: 56),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: signedIn
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile!.displayName ?? profile!.email,
                      style: AppTextTheme.titleMedium.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      profile!.email,
                      style: AppTextTheme.bodySmall.copyWith(
                        color: AppColors.ash,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Belum sign-in',
                      style: AppTextTheme.titleMedium.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: () => _signIn(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Sign in with Google'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(userProfileProvider.notifier).signIn();
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign-in Google gagal: $error',
            style: AppTextTheme.bodySmall.copyWith(color: AppColors.ink),
          ),
          backgroundColor: AppColors.surfaceHover,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _AutoBackupToggle extends ConsumerWidget {
  const _AutoBackupToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(autoBackupEnabledProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: AppColors.primary,
        title: Text(
          'Backup ke Google Drive',
          style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
        ),
        subtitle: Text(
          'Aktifkan untuk bisa backup lagu ke Drive',
          style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
        ),
        value: enabled,
        onChanged: (value) =>
            ref.read(autoBackupEnabledProvider.notifier).toggle(value),
      ),
    );
  }
}

class _BackupSummary extends ConsumerWidget {
  const _BackupSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(backupSummaryProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        '${summary.done} dari ${summary.total} lagu ter-backup',
        style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
      ),
    );
  }
}

/// Trigger backup manual (Architecture.md § 4c, revisi 2026-08-07) 
/// dipilih ganti trigger otomatis-WiFi supaya popup pilih-akun Google
/// (kalau device-nya butuh) terasa jadi kelanjutan wajar dari tap user.
class _ManualBackupButton extends ConsumerWidget {
  const _ManualBackupButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoBackupOn = ref.watch(autoBackupEnabledProvider);
    final state = ref.watch(manualBackupProvider);
    final running = state.isLoading;

    ref.listen<AsyncValue<void>>(manualBackupProvider, (previous, next) {
      if (previous?.isLoading != true) return;
      next.whenOrNull(
        error: (error, _) => _showSnackBar(context, '$error'),
        data: (_) => _showSnackBar(context, 'Backup selesai.'),
      );
    });

    if (!autoBackupOn) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: running
            ? null
            : () => ref.read(manualBackupProvider.notifier).backupNow(),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
        ),
        child: running
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Backup Sekarang'),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextTheme.bodySmall.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.surfaceHover,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => _confirmSignOut(context, ref),
      child: Text(
        'Sign out',
        style: AppTextTheme.labelMedium.copyWith(color: AppColors.danger),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Keluar dari akun Google?',
          style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Auto-backup berhenti sampai sign-in lagi.',
          style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(userProfileProvider.notifier).signOut();
    }
  }
}

/// Toggle + slider "Audio Enhancement" (Architecture.md § 7c, revisi
/// 2026-08-28)  dulu loudness enhancer + EQ aktif otomatis tanpa kontrol
/// user, dengan gain agresif yang bikin suara terasa "diwarnai" dibanding
/// app passthrough (mis. Telegram), makin kentara lewat Bluetooth SBC.
/// Sekarang default OFF (passthrough murni); user yang mau suara "lebih
/// hidup" mengaktifkan sendiri di sini dan atur levelnya lewat slider.
class _AudioEnhancementSection extends ConsumerWidget {
  const _AudioEnhancementSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(audioEnhancementEnabledProvider);
    final gain = ref.watch(audioEnhancementGainProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            'Audio',
            style: AppTextTheme.labelMedium.copyWith(color: AppColors.ash),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                title: Text(
                  'Audio Enhancement',
                  style: AppTextTheme.bodyMedium.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                subtitle: Text(
                  'Bass boost & clarity. Default: playback apa '
                  'adanya, tanpa diwarnai.',
                  style: AppTextTheme.bodySmall.copyWith(
                    color: AppColors.ash,
                  ),
                ),
                value: enabled,
                onChanged: (value) => ref
                    .read(audioEnhancementEnabledProvider.notifier)
                    .toggle(value),
              ),
              if (enabled) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Level',
                        style: AppTextTheme.bodySmall.copyWith(
                          color: AppColors.ash,
                        ),
                      ),
                    ),
                    Text(
                      '${gain.toStringAsFixed(1)} dB',
                      style: AppTextTheme.bodySmall.copyWith(
                        color: AppColors.ash,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: gain,
                  min: 0,
                  max: 6,
                  divisions: 12,
                  activeColor: AppColors.primary,
                  onChanged: (value) => ref
                      .read(audioEnhancementGainProvider.notifier)
                      .setGain(value),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
