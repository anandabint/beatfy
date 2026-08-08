import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'providers/cloud_backup_providers.dart';
import 'providers/onboarding_providers.dart';
import 'providers/playback_providers.dart';
import 'screens/now_playing/now_playing_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/restore/restore_screen.dart';
import 'screens/shell/main_shell.dart';

/// Global — dipakai [notificationClickedProvider] listener untuk push
/// [NowPlayingScreen] dari mana pun (Architecture.md § 4a), termasuk saat
/// notification di-tap dari state app manapun (foreground/background/belum
/// jalan sama sekali), tanpa perlu `BuildContext` lokal.
final rootNavigatorKey = GlobalKey<NavigatorState>();

class BeatfyApp extends ConsumerWidget {
  const BeatfyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(notificationClickedProvider, (previous, next) {
      final wasClicked = previous?.value ?? false;
      final isClicked = next.value ?? false;
      // Edge-triggered — `notificationClicked` adalah `ValueStream` yang
      // tetap `true` sampai event berikutnya, bukan reset otomatis. Cuma
      // navigasi saat transisi false→true, bukan tiap kali provider rebuild.
      if (!wasClicked && isClicked) {
        final navigator = rootNavigatorKey.currentState;
        if (navigator == null) return;
        final mediaItem = ref.read(currentMediaItemProvider).value;
        navigator.push(
          MaterialPageRoute(
            builder: (_) => NowPlayingScreen(
              heroTag: mediaItem != null
                  ? 'song-artwork-${mediaItem.id}'
                  : 'song-artwork-notification',
            ),
          ),
        );
      }
    });

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Beatfy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      scrollBehavior: const AppScrollBehavior(),
      home: const _RootGate(),
    );
  }
}

/// Gate root: [OnboardingScreen] dulu kalau belum pernah dilihat
/// (Architecture.md § 4b), baru setelah itu gate restore penuh (PRD.md § 7
/// poin 5): kalau `songs` box kosong tapi akun Drive punya folder backup
/// berisi file, tampilkan [RestoreScreen] dulu (tidak bisa di-skip) sebelum
/// [MainShell] — kalau tidak, langsung [MainShell] seperti biasa. Cloud
/// backup upload sendiri **tidak** trigger otomatis dari sini (Architecture.md
/// § 4c) — cuma lewat tombol "Backup Sekarang" eksplisit di Settings.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSeenOnboarding = ref.watch(onboardingProvider);
    if (!hasSeenOnboarding) return const OnboardingScreen();

    final gate = ref.watch(restoreGateProvider);

    return gate.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stackTrace) => const MainShell(),
      data: (state) => state.needsRestore
          ? RestoreScreen(files: state.files)
          : const MainShell(),
    );
  }
}
