import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/library_group.dart';
import '../../providers/favorite_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/common/add_to_playlist_sheet.dart';
import '../../widgets/common/song_actions_sheet.dart';
import '../../widgets/common/song_row.dart';

/// Detail satu grup Album/Artist/Folder — generic, dipakai untuk ketiganya
/// (PRD.md § 7 poin 6: strukturnya identik, cukup 1 screen reusable).
/// Reuse [SongRow] + [showSongActionsSheet] persis seperti Library flat list.
///
/// **Mode pilih-banyak (ditambahkan sesi ini)**: tap ikon "Pilih lagu" di
/// AppBar buat masuk mode select — tap row buat toggle centang (bukan play),
/// ikon "Pilih Semua"/"Batalkan semua" di AppBar, lalu tombol "Tambah ke
/// Playlist (N)" di bawah buat nambahin semua lagu terpilih sekaligus lewat
/// [showAddSongsToPlaylistSheet] — supaya tidak perlu buka context menu
/// satu-satu per lagu tiap mau nambah banyak lagu dari satu folder/album ke
/// playlist. Long-press (context menu single-song, `showSongActionsSheet`)
/// tetap berlaku seperti biasa di luar mode select.
class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.group});

  final LibraryGroup group;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final Set<int> _selected = {};
  bool _selecting = false;

  void _enterSelectionMode() {
    HapticFeedback.mediumImpact();
    setState(() => _selecting = true);
  }

  void _cancelSelection() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _toggle(int songId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.add(songId)) _selected.remove(songId);
    });
  }

  void _toggleSelectAll() {
    final allIds = widget.group.songs.map((s) => s.id);
    setState(() {
      if (_selected.length == widget.group.songs.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(allIds);
      }
    });
  }

  Future<void> _addSelectedToPlaylist() async {
    final songs = widget.group.songs
        .where((song) => _selected.contains(song.id))
        .toList();
    if (songs.isEmpty) return;
    await showAddSongsToPlaylistSheet(context, songs);
    if (mounted) _cancelSelection();
  }

  @override
  Widget build(BuildContext context) {
    final currentSongId = ref.watch(currentMediaItemProvider).value?.id;
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final songs = widget.group.songs;
    final allSelected = songs.isNotEmpty && _selected.length == songs.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: _selecting
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Batal',
                onPressed: _cancelSelection,
              )
            : null,
        title: Text(
          _selecting ? '${_selected.length} dipilih' : widget.group.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
        ),
        actions: [
          if (_selecting)
            IconButton(
              icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
              tooltip: allSelected ? 'Batalkan semua' : 'Pilih semua',
              onPressed: _toggleSelectAll,
            )
          else
            IconButton(
              icon: const Icon(Icons.playlist_add_check_rounded),
              tooltip: 'Pilih lagu',
              onPressed: songs.isEmpty ? null : _enterSelectionMode,
            ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(
          bottom: _selecting ? AppSpacing.xxxl * 2 : AppSpacing.xxxl,
        ),
        // Semua row seragam tinggi — skip layout pass per-item saat scroll
        // (audit performa PRD.md § 11, 2026-08-07).
        prototypeItem: SongRow(song: songs.first, onTap: () {}),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final isFavorite = favoriteIds.contains(song.id);
          final isSelected = _selected.contains(song.id);
          return SongRow(
            song: song,
            active: song.id.toString() == currentSongId,
            onTap: _selecting
                ? () => _toggle(song.id)
                : () => ref
                      .read(audioHandlerProvider)
                      .playFromSongs(songs, index),
            onLongPress: _selecting
                ? null
                : () => showSongActionsSheet(context, song),
            trailing: _selecting
                ? Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : AppColors.ash,
                  )
                : IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.primary : AppColors.ash,
                    ),
                    tooltip: isFavorite
                        ? 'Hapus dari favorit'
                        : 'Tandai favorit',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(favoriteIdsProvider.notifier).toggle(song.id);
                    },
                  ),
          );
        },
      ),
      bottomNavigationBar: _selecting
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selected.isEmpty
                        ? null
                        : _addSelectedToPlaylist,
                    icon: const Icon(Icons.playlist_add),
                    label: Text('Tambah ke Playlist (${_selected.length})'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
