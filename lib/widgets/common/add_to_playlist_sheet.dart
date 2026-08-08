import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/song.dart';
import '../../providers/playlist_providers.dart';

/// Picker "Tambah ke playlist" — dibuka dari context menu song (long-press),
/// Design.md § 7 "Context menu song". Tap toggle langsung (sama pola dengan
/// [AddSongsToPlaylistScreen], tapi arah sebaliknya: dari satu song, pilih
/// playlist mana — bukan dari satu playlist, pilih banyak song).
Future<void> showAddToPlaylistSheet(BuildContext context, Song song) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddToPlaylistSheet(song: song),
  );
}

class _AddToPlaylistSheet extends ConsumerStatefulWidget {
  const _AddToPlaylistSheet({required this.song});

  final Song song;

  @override
  ConsumerState<_AddToPlaylistSheet> createState() =>
      _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<_AddToPlaylistSheet> {
  bool _creatingNew = false;
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _createAndAdd() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(playlistsProvider.notifier);
    await notifier.create(name);
    final created = ref
        .read(playlistsProvider)
        .where((p) => p.name == name)
        .toList();
    if (created.isNotEmpty) {
      await notifier.addSong(created.first.id, widget.song.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
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
              'Tambah ke playlist',
              style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_creatingNew) ...[
              TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                autofocus: true,
                style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Nama playlist baru',
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
                onSubmitted: (_) => _createAndAdd(),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _creatingNew = false),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ElevatedButton(
                    onPressed: _createAndAdd,
                    child: const Text('Buat & Tambah'),
                  ),
                ],
              ),
            ] else ...[
              Flexible(
                child: playlists.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          'Belum ada playlist.',
                          style: AppTextTheme.bodySmall.copyWith(
                            color: AppColors.ash,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          final added = playlist.songIds.contains(
                            widget.song.id,
                          );
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              playlist.name,
                              style: AppTextTheme.bodyMedium.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                            subtitle: Text(
                              '${playlist.songIds.length} lagu',
                              style: AppTextTheme.caption.copyWith(
                                color: AppColors.stone,
                              ),
                            ),
                            trailing: Icon(
                              added
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: added ? AppColors.primary : AppColors.ash,
                            ),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              final notifier = ref.read(
                                playlistsProvider.notifier,
                              );
                              if (added) {
                                notifier.removeSong(
                                  playlist.id,
                                  widget.song.id,
                                );
                              } else {
                                notifier.addSong(playlist.id, widget.song.id);
                              }
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => setState(() => _creatingNew = true),
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: Text(
                  'Playlist baru',
                  style: AppTextTheme.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
