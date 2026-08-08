import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/theme/artwork_gradients.dart';
import '../../models/song.dart';

/// Artwork — Design.md § 8 (revisi 2026-08-06): **circular**, bukan
/// rounded-square lagi. Embedded artwork lokal lewat `on_audio_query` (tidak
/// ada network image loader). Kalau tidak ada artwork, fallback ke gradient
/// blok warna berbasis hash nama artist/album (bukan foto/logo generik),
/// di-crop lingkaran seperti artwork asli.
///
/// Ambil parameter primitif (bukan langsung [Song]) supaya bisa dipakai juga
/// dari [MediaItem] (mini player, Now Playing) yang cuma punya id/extras,
/// tanpa perlu roundtrip ke [Song] lengkap.
class SongArtwork extends StatelessWidget {
  const SongArtwork({
    super.key,
    this.albumArtId,
    required this.gradientSeed,
    this.size = 48,
  });

  factory SongArtwork.ofSong(Song song, {double size = 48}) {
    return SongArtwork(
      albumArtId: song.albumArtId,
      gradientSeed: ArtworkGradients.songSeed(song.title, song.artist),
      size: size,
    );
  }

  /// Album id dari MediaStore — null berarti tidak ada grouping album, selalu
  /// pakai placeholder gradient.
  final int? albumArtId;
  final String gradientSeed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = _GradientPlaceholder(seed: gradientSeed, size: size);

    return ClipOval(
      child: albumArtId == null
          ? placeholder
          : QueryArtworkWidget(
              id: albumArtId!,
              type: ArtworkType.ALBUM,
              artworkWidth: size,
              artworkHeight: size,
              artworkFit: BoxFit.cover,
              artworkBorder: BorderRadius.zero,
              keepOldArtwork: true,
              nullArtworkWidget: placeholder,
            ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.seed, required this.size});

  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = ArtworkGradients.forSeed(seed);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note,
        color: Colors.white.withValues(alpha: 0.85),
        size: size * 0.45,
      ),
    );
  }
}
