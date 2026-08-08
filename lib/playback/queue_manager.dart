import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../data/local/hive/playback_state_cache.dart' show RepeatMode;
import '../models/song.dart';

/// Konversi antara [Song] (domain model) dan representasi queue yang dipakai
/// just_audio/audio_service. AudioHandler tetap satu-satunya yang memanggil
/// method player (Architecture.md § 4) — kelas ini murni transformasi data,
/// tidak pernah pegang referensi ke [ja.AudioPlayer].
///
/// Shuffle/repeat/next/prev sendiri dijalankan oleh engine playlist
/// `just_audio` (`AudioPlayer.setAudioSources` + `shuffleModeEnabled` +
/// `loopMode`) alih-alih ditulis ulang manual di sini — engine itu sudah
/// battle-tested untuk wraparound, single-item loop, dan gapless transition,
/// jadi risiko glitch jauh lebih kecil dibanding reimplementasi index math
/// sendiri (prioritas #1 Rules.md § 3: playback tidak boleh glitch).
abstract final class QueueManager {
  /// Daftar `AudioSource` just_audio dari [songs], urutan sama persis dengan
  /// [songs] (urutan "asli"/logis — shuffle diterapkan di atas urutan ini
  /// oleh player, bukan mengubah urutan ini).
  static List<ja.AudioSource> toAudioSources(List<Song> songs) =>
      songs.map(toAudioSource).toList();

  static ja.AudioSource toAudioSource(Song song) {
    return ja.AudioSource.uri(Uri.parse(song.filePath), tag: toMediaItem(song));
  }

  /// Dipakai audio_service untuk notification/lock-screen/queue broadcast.
  ///
  /// `artUri` pakai `content://` MediaStore langsung (bukan fetch bytes ke
  /// file sementara) — audio_service meneruskan URI `content://` apa adanya
  /// ke sisi native Android.
  ///
  /// Fix bug: sebelumnya `artUri` di-suffix `/albumart`
  /// (`.../media/<id>/albumart`), URI yang TIDAK dikenali `ContentResolver`
  /// manapun — bukan pattern resmi MediaStore. Padahal sisi native
  /// `audio_service` (`AudioService.java#setMetadata` →
  /// `loadArtBitmap(artUri, loadThumbnailUri)`) memanggil
  /// `ContentResolver.loadThumbnail()` (Android Q+) langsung di atas nilai
  /// `artUri` itu sendiri — bukan di atas nilai extra `loadThumbnailUri`,
  /// yang cuma dipakai sebagai flag non-null untuk memilih code path
  /// `loadThumbnail` vs `openFileDescriptor`. Akibatnya URI yang salah itu
  /// gagal di-resolve (exception ke-catch diam-diam di sisi native), jadi
  /// notification/lock-screen selalu tampil tanpa artwork sama sekali —
  /// termasuk untuk lagu yang jelas punya art tertanam (`SongArtwork` di UI
  /// tetap menampilkannya benar lewat jalur `on_audio_query`, cuma jalur
  /// `MediaItem.artUri` ini yang salah). `artUri` sekarang pakai URI lagu
  /// polos (`content://media/external/audio/media/<id>`, tanpa suffix apa
  /// pun) — persis apa yang dibutuhkan `loadThumbnail()` untuk resolve
  /// artwork tertanam.
  static MediaItem toMediaItem(Song song) {
    final contentUri = 'content://media/external/audio/media/${song.id}';
    return MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      artUri: Uri.parse(contentUri),
      extras: {
        if (song.albumArtId != null) 'albumArtId': song.albumArtId,
        'loadThumbnailUri': contentUri,
      },
    );
  }

  /// Urutan songId asli (bukan urutan shuffle) — dipakai untuk persist
  /// `queueSongIds` (Schema.md § 2).
  static List<int> songIdsOf(List<Song> songs) =>
      songs.map((s) => s.id).toList();

  static ja.LoopMode toLoopMode(RepeatMode mode) => switch (mode) {
    RepeatMode.off => ja.LoopMode.off,
    RepeatMode.one => ja.LoopMode.one,
    RepeatMode.all => ja.LoopMode.all,
  };
}
