import 'package:on_audio_query/on_audio_query.dart';

/// Wrapper tipis di atas `on_audio_query`  Architecture.md § 3, § 6.
///
/// Catatan: `on_audio_query` hanya query koleksi `MediaStore.Audio.Media`,
/// tidak mengekspos koleksi `MediaStore.Downloads` terpisah seperti
/// implementasi Kotlin versi lama (paket ini tidak punya API untuk itu).
/// Praktiknya file di folder Download tetap ikut selama sudah di-index media
/// scanner ke koleksi Audio.Media, yang mencakup mayoritas kasus nyata 
/// gap ini dilaporkan ke Pann, bukan diam-diam diterima.
class AudioQueryService {
  AudioQueryService([OnAudioQuery? query]) : _query = query ?? OnAudioQuery();

  final OnAudioQuery _query;

  Future<List<SongModel>> queryAllSongs() {
    return _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
  }
}
