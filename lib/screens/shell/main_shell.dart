import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/layout_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/now_playing/mini_player.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../playlist/playlist_list_screen.dart';
import '../search/search_screen.dart';

/// Root shell 4-tab; Architecture.md § 3a, Design.md § 7. `IndexedStack`
/// menjaga state tiap tab (scroll position dst) saat pindah-pindah; pola
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
      // `extendBody: true` (Architecture.md § 3a; fix arsitektural asli
      // sempat regresi jadi `false`, dikembalikan sesi ini); body/list tiap
      // tab dirender penuh sampai bawah layar, mengalir di balik area
      // MiniPlayer+NavBar, bukan berhenti di atasnya. Wajib untuk efek frosted
      // glass di bawah (revisi blur, sesi ini): `BackdropFilter` di dalam
      // MiniPlayer/_BottomNavBar butuh konten asli di baliknya untuk di-blur;
      // kalau body tidak extend, tidak ada apa-apa untuk di-sample, blur-nya
      // cuma nge-blur canvas kosong.
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
      bottomNavigationBar: _DockMeasurer(
        child: SafeArea(
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
      ),
    );
  }
}

/// Ukur tinggi asli dock (`MiniPlayer` + `_BottomNavBar`, termasuk safe-area
/// bawah) langsung dari layout nyata, lalu simpan ke [dockHeightProvider];
/// dipakai tiap tab (Home/Search/Library/Playlist) buat bottom padding
/// list-nya. Ini gantiin konstanta ditebak yang sebelumnya berulang kali
/// meleset dan jadi sumber bug "baris terakhir ketutup dock"/"gap kegedean"
/// bolak-balik (Architecture.md § 3a/§ 7e)  satu pengukuran nyata, otomatis
/// benar di device manapun dan kapan pun `MiniPlayer` muncul/hilang.
class _DockMeasurer extends ConsumerStatefulWidget {
  const _DockMeasurer({required this.child});

  final Widget child;

  @override
  ConsumerState<_DockMeasurer> createState() => _DockMeasurerState();
}

class _DockMeasurerState extends ConsumerState<_DockMeasurer> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  @override
  void didUpdateWidget(covariant _DockMeasurer oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  void _measure(Duration _) {
    if (!mounted) return;
    final height = _key.currentContext?.size?.height;
    if (height == null) return;
    final notifier = ref.read(dockHeightProvider.notifier);
    if (notifier.state != height) notifier.state = height;
  }

  @override
  Widget build(BuildContext context) {
    // `MiniPlayer` nampilin/nyembunyiin dirinya sendiri berdasar ada/tidaknya
    // sesi playback aktif (lihat `MiniPlayer.build`), yang mengubah tinggi
    // dock tanpa `_DockMeasurer` ini sendiri ikut rebuild; remeasure tiap
    // kali status itu berubah (bukan tiap frame  boros), supaya
    // `dockHeightProvider` tetap akurat begitu MiniPlayer muncul/hilang.
    ref.listen(currentMediaItemProvider, (previous, next) {
      final hadSong = previous?.value != null;
      final hasSong = next.value != null;
      if (hadSong != hasSong) {
        WidgetsBinding.instance.addPostFrameCallback(_measure);
      }
    });
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

/// Floating pill nav; Design.md § 7 (revisi 2026-08-07): kapsul melayang
/// dengan margin dari tepi layar (bukan bar full-width nempel edge),
/// icon-only (tanpa label teks), tab aktif = lingkaran solid lime
/// membungkus icon. **Revisi frosted glass (sesi ini)**: background solid
/// diganti translucent + `BackdropFilter` blur; list tab di baliknya
/// (`MainShell.extendBody: true` di atas) kelihatan blur lewat pill, bukan
/// ketutup rapat warna solid.
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
      // Isolasi `BackdropFilter` (mahal secara GPU) dari repaint tetangganya;
      // pola sama dengan `GradientBlob` (audit performa PRD.md § 11).
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.6),
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
