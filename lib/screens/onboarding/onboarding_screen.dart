import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/onboarding_providers.dart';
import '../../services/permission_service.dart';

/// Onboarding  Architecture.md § 4b, Design.md § 7. Muncul cuma sekali
/// (`AppPreferences.hasSeenOnboarding`), dipasang di `_RootGate` (app.dart)
/// sebelum `MainShell`/restore gate. 5 halaman dalam satu `PageView`: 3
/// slide intro, Permission screen, Sign-in screen  flat dark, **tanpa**
/// gradient blob (itu ciri khas Home/Now Playing saja, Design.md § 11).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _introSlideCount = 3;

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() =>
      ref.read(onboardingProvider.notifier).complete();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  const _IntroSlide(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Musik pribadi, lebih sederhana',
                    description:
                        'Putar musik yang tersimpan di HP kamu dengan mudah '
                        'cepat, nyaman, dan tanpa iklan.',
                  ),
                  const _IntroSlide(
                    icon: Icons.offline_bolt_rounded,
                    title: 'Nikmati musik secara offline',
                    description:
                        'Musik tetap tersimpan di perangkat dan dapat diputar tanpa internet. '
                        'Cloud hanya digunakan sebagai pengaman untuk data kamu.',
                  ),
                  const _IntroSlide(
                    icon: Icons.cloud_done_rounded,
                    title: 'Data tetap aman',
                    description:
                        'Cadangkan data Beatfy secara otomatis ke Google Drive pribadi kamu '
                        'opsional, tetapi siap digunakan saat kamu berganti atau mereset HP.',
                  ),
                  _PermissionPage(onDone: () => _goTo(_introSlideCount + 1)),
                  _SignInPage(onDone: _finish),
                ],
              ),
            ),
            if (_page < _introSlideCount) ...[
              _DotIndicator(count: _introSlideCount, activeIndex: _page),
              const SizedBox(height: AppSpacing.lg),
              _IntroNavRow(
                onSkipIntro: () => _goTo(_introSlideCount),
                onNext: () => _goTo(_page + 1),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _IntroNavRow extends StatelessWidget {
  const _IntroNavRow({required this.onSkipIntro, required this.onNext});

  final VoidCallback onSkipIntro;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onSkipIntro,
            child: Text(
              'Lewati intro',
              style: AppTextTheme.labelMedium.copyWith(color: AppColors.ash),
            ),
          ),
          ElevatedButton(onPressed: onNext, child: const Text('Lanjut')),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 44),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextTheme.displayLarge.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ash),
          ),
        ],
      ),
    );
  }
}

/// Permission screen  Design.md § 7. "Izinkan" memicu system permission
/// dialog Android (`PermissionService`, reuse logic v1) lalu lanjut ke
/// halaman berikutnya terlepas hasilnya (izin bisa diberikan kapan saja
/// nanti dari pengaturan sistem  onboarding tidak boleh macet di sini,
/// konsisten prinsip "tidak memaksa", PRD.md § 5).
class _PermissionPage extends StatefulWidget {
  const _PermissionPage({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<_PermissionPage> {
  bool _requesting = false;

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    try {
      await PermissionService.request();
    } finally {
      if (mounted) widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.perm_media_rounded,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Izinkan akses musik',
            textAlign: TextAlign.center,
            style: AppTextTheme.displayLarge.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Beatfy perlu izin baca file audio buat nemuin lagu yang udah '
            'ada di HP kamu. Semua tetap lokal, nggak ada yang dikirim ke '
            'mana-mana.',
            textAlign: TextAlign.center,
            style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ash),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _requesting ? null : _requestPermission,
              child: const Text('Izinkan'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sign-in screen (akhir onboarding)  Design.md § 7. Sama komponen dipakai
/// ulang untuk tombol login di Settings. Login sukses maupun skip
/// sama-sama memanggil [onDone] (Architecture.md § 4b)  tidak pernah jadi
/// login wall.
class _SignInPage extends ConsumerStatefulWidget {
  const _SignInPage({required this.onDone});

  final Future<void> Function() onDone;

  @override
  ConsumerState<_SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<_SignInPage> {
  bool _signingIn = false;

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    try {
      await ref.read(userProfileProvider.notifier).signIn();
      await widget.onDone();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _signingIn = false);
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.backup_rounded,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Login sekarang, biar makin aman',
            textAlign: TextAlign.center,
            style: AppTextTheme.displayLarge.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Auto-backup lagu ke Google Drive kamu sendiri, dan tetap aman '
            'walau HP di-reset atau ganti. Boleh login kapan aja nanti '
            'lewat Settings kalau belum siap sekarang.',
            textAlign: TextAlign.center,
            style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ash),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _signingIn ? null : _signIn,
              child: _signingIn
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Lanjut dengan Google'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _signingIn ? null : widget.onDone,
            child: Text(
              'Lewati',
              style: AppTextTheme.labelMedium.copyWith(color: AppColors.ash),
            ),
          ),
        ],
      ),
    );
  }
}
