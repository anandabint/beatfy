/// Port dari `TitleCleaner.kt` (versi Kotlin lama) — Architecture.md § 3, § 6.
///
/// Strip noise text umum di judul hasil download ("Official Audio", tag
/// bitrate, dst) dan pecah pola nama file "Artist - Title" kalau field
/// artist dari MediaStore kosong/tidak diketahui.
abstract final class TitleCleaner {
  static final _bracketJunk = RegExp(
    r'[\(\[][^\)\]]*\b(official|lyrics?|video|audio|mp3|download|youtube|hq|hd|ncs)\b[^\)\]]*[\)\]]',
    caseSensitive: false,
  );
  static final _downloadYoutubeTail = RegExp(
    r'\b(download|youtube)\b.*$',
    caseSensitive: false,
  );
  static final _trailingJunkWords = RegExp(
    r'\s*\b(mp3|hq|hd)\b\s*$',
    caseSensitive: false,
  );
  static final _bitrate = RegExp(
    r'\b\d{2,4}\s?(kbps|kb/s)\b',
    caseSensitive: false,
  );
  static final _trailingSeparator = RegExp(r'[\s\-|_]+$');
  static final _multiSpace = RegExp(r'\s{2,}');
  static final _underscore = RegExp(r'_+');

  /// Separator dash yang biasa dipakai judul unduhan gaya "Artis - Judul".
  static final _artistTitleSeparator = RegExp(r'\s+[-–—]\s+');

  static const _unknownArtistMarkers = {
    'unknown artist',
    '<unknown>',
    'unknown',
  };

  static String clean(String raw) {
    var result = raw.replaceAll(_underscore, ' ');
    result = result.replaceAll(_bracketJunk, '');
    result = result.replaceAll(_downloadYoutubeTail, '');
    result = result.replaceAll(_bitrate, '');
    result = result.replaceAll(_trailingJunkWords, '');
    result = result.replaceAll(_multiSpace, ' ');
    result = result.replaceAll(_trailingSeparator, '');
    result = result.trim();
    return result.isEmpty ? raw.trim() : result;
  }

  /// Bersihkan judul mentah, dan kalau [rawArtist] kosong/tidak diketahui, coba
  /// pecah pola "Artis - Judul" yang umum dipakai nama file hasil unduhan
  /// menjadi field artist tersendiri.
  static CleanedMetadata parse(String rawTitle, String? rawArtist) {
    final cleanedTitle = clean(rawTitle);
    final hasRealArtist =
        rawArtist != null &&
        rawArtist.trim().isNotEmpty &&
        !_unknownArtistMarkers.contains(rawArtist.trim().toLowerCase());

    if (hasRealArtist) {
      return CleanedMetadata(title: cleanedTitle, artist: rawArtist.trim());
    }

    // Cuma pecah kalau separatornya muncul TEPAT sekali — kalau ada beberapa
    // " - " (mis. "Al - Kahfi - hasa albalushi"), ambigu mana yang batas
    // artis/judul, jadi dibiarkan saja daripada salah tebak.
    final separatorMatches = _artistTitleSeparator
        .allMatches(cleanedTitle)
        .toList();
    if (separatorMatches.length == 1) {
      final separator = separatorMatches.first;
      final artistCandidate = cleanedTitle.substring(0, separator.start).trim();
      final titleCandidate = cleanedTitle.substring(separator.end).trim();
      if (artistCandidate.isNotEmpty && titleCandidate.isNotEmpty) {
        return CleanedMetadata(title: titleCandidate, artist: artistCandidate);
      }
    }

    final trimmedRawArtist = rawArtist?.trim();
    final looksUnknown =
        trimmedRawArtist == null ||
        trimmedRawArtist.isEmpty ||
        _unknownArtistMarkers.contains(trimmedRawArtist.toLowerCase());
    return CleanedMetadata(
      title: cleanedTitle,
      artist: looksUnknown ? 'Unknown Artist' : trimmedRawArtist,
    );
  }
}

class CleanedMetadata {
  const CleanedMetadata({required this.title, required this.artist});

  final String title;
  final String artist;
}
