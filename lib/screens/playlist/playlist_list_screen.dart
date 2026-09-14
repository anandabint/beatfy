import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/playlist.dart';
import '../../providers/layout_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/playlist_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/song_artwork.dart';
import 'playlist_detail_screen.dart';

/// Playlist tab; list semua playlist (PRD.md § 7 poin 1).
class PlaylistListScreen extends ConsumerWidget {
  const PlaylistListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    // Body extend di balik dock buat frosted glass (MainShell.extendBody:
    // true, Architecture.md § 3a); padding bawah dipakai dari tinggi dock
    // hasil pengukuran layout nyata (`dockHeightProvider`, bukan konstanta
    // ditebak) supaya baris terakhir grid tetap bisa discroll sepenuhnya di
    // atas MiniPlayer+NavBar, bukan permanen ketutup (§ 7e).
    final dockClearance = ref.watch(dockHeightProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Playlist',
          style: AppTextTheme.displayLarge.copyWith(color: AppColors.ink),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: _NewPlaylistCard(),
          ),
          Expanded(
            child: playlists.isEmpty
                ? const EmptyState(
                    icon: Icons.queue_music_rounded,
                    message:
                        'Belum ada playlist. Tap "New Playlist" di atas untuk buat baru.',
                  )
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      dockClearance + AppSpacing.lg,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.65,
                        ),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return Dismissible(
                        key: ValueKey(playlist.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) =>
                            _confirmDelete(context, playlist),
                        onDismissed: (_) => ref
                            .read(playlistsProvider.notifier)
                            .delete(playlist.id),
                        child: _PlaylistCard(
                          playlist: playlist,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaylistDetailScreen(playlistId: playlist.id),
                            ),
                          ),
                          onRename: () =>
                              _showRenameDialog(context, ref, playlist),
                          onDelete: () async {
                            final confirmed = await _confirmDelete(
                              context,
                              playlist,
                            );
                            if (confirmed == true) {
                              await ref
                                  .read(playlistsProvider.notifier)
                                  .delete(playlist.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final controller = TextEditingController(text: playlist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          _NameDialog(title: 'Ganti nama playlist', controller: controller),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;

    await ref.read(playlistsProvider.notifier).rename(playlist.id, name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Playlist diganti nama jadi "${name.trim()}"',
          style: AppTextTheme.bodySmall.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.surfaceHover,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Dialog konfirmasi sebelum playlist benar-benar hilang; dipakai baik
  /// dari swipe-to-delete (`confirmDismiss`) maupun menu "Hapus".
  static Future<bool?> _confirmDelete(BuildContext context, Playlist playlist) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Hapus "${playlist.name}"?',
          style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Lagu di dalamnya tidak ikut terhapus dari HP.',
          style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

/// Dashed-border card; tap membuka form lewat `showModalBottomSheet`
/// (bukan expand inline lagi, lihat § catatan di bawah).
///
/// Fix bug: form inline sebelumnya expand di dalam `Scaffold` tab Playlist,
/// yang punya `resizeToAvoidBottomInset` default true; begitu keyboard
/// muncul, `MainShell` (outer Scaffold pembungkus bottom nav + mini player)
/// ikut resize body-nya, jadi nav+mini player kedorong naik di atas keyboard.
/// Modal bottom sheet dirender lewat `Navigator` overlay di atas seluruh
/// shell (bukan bagian dari layout body tab manapun), jadi otomatis
/// menutupi nav+mini-player alih-alih mendorongnya, dan padding keyboard-nya
/// ditangani lokal di dalam sheet (lihat `_NewPlaylistSheet`).
class _NewPlaylistCard extends ConsumerWidget {
  const _NewPlaylistCard();

  void _openSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NewPlaylistSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        radius: AppRadius.lg,
        color: AppColors.hairline,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSheet(context),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'New Playlist',
                  style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Form "buat playlist baru", isi bottom sheet yang dibuka `_NewPlaylistCard`.
class _NewPlaylistSheet extends ConsumerStatefulWidget {
  const _NewPlaylistSheet();

  @override
  ConsumerState<_NewPlaylistSheet> createState() => _NewPlaylistSheetState();
}

class _NewPlaylistSheetState extends ConsumerState<_NewPlaylistSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Sheet baru selesai animasi masuk setelah frame pertama; request focus
    // di post-frame supaya keyboard muncul begitu sheet kelihatan, bukan
    // race dengan transisi masuknya.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await ref.read(playlistsProvider.notifier).create(name);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Padding manual mengikuti viewInsets.bottom (tinggi keyboard); sheet
    // ini sendiri bukan Scaffold jadi tidak ada resizeToAvoidBottomInset
    // otomatis, harus diurus sendiri supaya form selalu terlihat di atas
    // keyboard.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New Playlist',
              style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Nama playlist',
                hintStyle: AppTextTheme.bodyMedium.copyWith(
                  color: AppColors.stone,
                ),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: AppSpacing.xs),
                ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const gapWidth = 4.0;
    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashedPath.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + gapWidth;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _PlaylistCard extends ConsumerWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverSong = playlist.coverSongId != null
        ? ref.watch(libraryRepositoryProvider).getById(playlist.coverSongId!)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              // SongArtwork sudah circular sendiri (Design.md § 5); badge
              // ditumpuk di sudut kanan-bawah lingkaran, pola avatar+badge.
              child: Stack(
                children: [
                  Positioned.fill(
                    child: coverSong != null
                        ? SongArtwork.ofSong(coverSong, size: double.infinity)
                        : SongArtwork(
                            gradientSeed: playlist.name,
                            size: double.infinity,
                          ),
                  ),
                  const Positioned(right: 4, bottom: 4, child: _TintedIcon()),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextTheme.bodyMedium.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.ash,
                    size: 18,
                  ),
                  onSelected: (value) {
                    if (value == 'rename') onRename();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(
                        'Ganti nama',
                        style: AppTextTheme.bodyMedium.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Hapus',
                        style: AppTextTheme.bodyMedium.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '${playlist.songIds.length} lagu',
              style: AppTextTheme.caption.copyWith(color: AppColors.stone),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tinted leading icon; Design.md § 12: kotak circular (revisi § 5), bg
/// `primary` 15% opacity, icon solid `primary`. Badge kecil di pojok cover
/// biar tiap card kelihatan jelas "ini playlist" walau covernya album art.
class _TintedIcon extends StatelessWidget {
  const _TintedIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.canvas, width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.queue_music_rounded,
        color: Colors.black,
        size: 12,
      ),
    );
  }
}

class _NameDialog extends StatelessWidget {
  const _NameDialog({required this.title, required this.controller});

  final String title;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        title,
        style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceMuted,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
