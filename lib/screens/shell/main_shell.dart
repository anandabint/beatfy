import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/now_playing/mini_player.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../playlist/playlist_list_screen.dart';
import '../search/search_screen.dart';

/// Root shell 4-tab — Architecture.md § 3a, Design.md § 7. `IndexedStack`
/// menjaga state tiap tab (scroll position dst) saat pindah-pindah — pola
/// struktural dari `main_shell.dart` Planly, warna 100% ikut Design.md
/// (bukan navy/teal Planly).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      // Pola Planly (Architecture.md § 3a, revisi 2026-08-08): pakai slot
      // `bottomNavigationBar` bawaan Scaffold alih-alih `Column` manual —
      // Flutter yang mengatur ruang body otomatis, tidak ada lagi clearance
      // yang perlu ditebak manual per-screen. `extendBody: true` bikin body
      // (tiap tab) scroll penuh sampai bawah layar, transparan di balik
      // MiniPlayer+NavBar yang tetap "timbul" mengambang di atasnya.
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          SearchScreen(),
          LibraryScreen(),
          PlaylistListScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            _BottomNavBar(
              currentIndex: _index,
              onTap: (index) => setState(() => _index = index),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating pill nav — Design.md § 7 (revisi 2026-08-07): kapsul melayang
/// dengan margin dari tepi layar (bukan bar full-width nempel edge),
/// icon-only (tanpa label teks), tab aktif = lingkaran solid lime
/// membungkus icon.
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.library_music_rounded,
    Icons.queue_music_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _icons.length; i++)
                _NavItem(
                  icon: _icons[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: active ? Colors.black : AppColors.ash,
            size: 22,
          ),
        ),
      ),
    );
  }
}
