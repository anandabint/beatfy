import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// **WAJIB diisi Pann sebelum sign-in bisa jalan di Android**  client ID
/// OAuth bertipe *Web application* (bukan client Android) dari Google Cloud
/// Console. Project ini tidak pakai Firebase/`google-services.json`, jadi
/// `serverClientId` harus di-supply manual saat `GoogleSignIn.initialize()`
/// (lihat README `google_sign_in_android`). Ini client ID publik, bukan
/// client secret  aman ditulis di source, tapi tetap butuh dibuat dulu di
/// Cloud Console (langkah manual, di luar kendali Claude Code, dijelaskan
/// terpisah ke Pann).
const _googleServerClientId =
    '825315718744-de5b086fshmdm3clgfjnn1do9tar8isv.apps.googleusercontent.com'; // TODO(Pann): isi dari Google Cloud Console

/// Wrapper tipis di atas Google Sign-In SDK (Architecture.md § 1, § 7).
/// Murni auth  tidak menyentuh Hive, persistensi lokal jadi tanggung jawab
/// `UserProfileRepository` lewat `providers/auth_providers.dart`. Dipisah
/// jadi service sendiri (bukan ditempel di widget Home) supaya bisa
/// di-reuse langsung saat sesi cloud backup Google Drive nanti  scope
/// tambahan (Drive API access) tinggal ditambah lewat
/// `GoogleSignInAccount.authorizationClient`, tanpa perlu tulis ulang auth.
abstract final class AuthService {
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
    _initialized = true;
  }

  /// Trigger sign-in interaktif  wajib dipanggil dari user interaction
  /// (tap avatar), bukan otomatis saat app start. Error dilempar apa adanya
  /// supaya UI bisa kasih feedback jelas ke user (mis. "belum dikonfigurasi"),
  /// beda dari [attemptSilentSignIn] yang harus selalu diam.
  static Future<GoogleSignInAccount> signIn() async {
    await _ensureInitialized();
    return GoogleSignIn.instance.authenticate();
  }

  static Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }

  /// Scope Drive (Architecture.md § 7)  cuma file yang dibuat app sendiri
  /// (`drive.file`), bukan full Drive access. Sesuai `docs/CloudSetup.md`
  /// § 2 poin 4.
  static const driveScopes = <String>[
    'https://www.googleapis.com/auth/drive.file',
  ];

  /// `http.Client` yang sudah nempel header `Authorization: Bearer <token>`
  /// buat dipakai `googleapis`' `DriveApi`  pola standar
  /// `google_sign_in` + `googleapis` tanpa perlu `googleapis_auth` (itu buat
  /// service-account/desktop flow, bukan mobile). Dilempar apa adanya kalau
  /// user belum sign-in atau authorization Drive tidak didapat  caller
  /// (`CloudBackupService`) yang tanggung jawab memastikan hanya dipanggil
  /// saat user memang sudah sign-in.
  ///
  /// [promptIfNecessary] **wajib `false`** (default) untuk semua pemanggilan
  /// otomatis/background (trigger WiFi, restore gate saat cold start)  `true`
  /// menampilkan consent screen Google secara interaktif (bisa mode fullscreen
  /// blocking), yang kalau muncul tanpa gesture user jadi pelanggaran
  /// eksplisit prinsip "otomatis, silent" auto-backup (PRD.md § 2 poin 4).
  /// Ditemukan sebagai bug nyata saat QC device (2026-08-07): dengan `true`
  /// di jalur otomatis, consent screen muncul sendiri tiap cold start selama
  /// WiFi nyala  sudah diperbaiki, `true` sekarang hanya dipakai dari
  /// [UserProfileNotifier.signIn] (tap eksplisit "Sign in with Google").
  ///
  /// Diserialize lewat [_authLock] (2026-08-07, fix auto-backup 0/17):
  /// dua caller otomatis bisa jalan nyaris bersamaan saat cold start
  /// (`RestoreGateNotifier.build()` + `ConnectivityBackupNotifier._init()`
  /// kalau WiFi sudah nyala)  masing-masing manggil
  /// `attemptLightweightAuthentication()` sendiri-sendiri secara paralel.
  /// Ini kemungkinan besar penyebab asli bottom-sheet "Signing you in" yang
  /// dilaporkan Pann di device 2-akun Google (bukan murni soal "dipanggil
  /// saat cold start"  Credential Manager tampaknya jatuh ke UI chooser
  /// kalau ada 2 request lightweight-auth bersamaan). Mutex ini bikin semua
  /// panggilan `getDriveAuthClient` app-wide antre satu-satu, jadi tidak
  /// pernah ada dua request native berbarengan  sambil tetap membolehkan
  /// trigger WiFi cek status cold-start (lihat `cloud_backup_providers.dart`).
  static Future<void> _authLock = Future.value();

  static Future<http.Client> getDriveAuthClient({
    bool promptIfNecessary = false,
  }) async {
    final previous = _authLock;
    final completer = Completer<void>();
    _authLock = completer.future;
    await previous;
    try {
      return await _getDriveAuthClient(promptIfNecessary: promptIfNecessary);
    } finally {
      completer.complete();
    }
  }

  static Future<http.Client> _getDriveAuthClient({
    required bool promptIfNecessary,
  }) async {
    debugPrint(
      '[CloudBackup] attemptLightweightAuthentication (promptIfNecessary=$promptIfNecessary)',
    );
    await _ensureInitialized();
    final account = await GoogleSignIn.instance
        .attemptLightweightAuthentication();
    if (account == null) {
      debugPrint('[CloudBackup] attemptLightweightAuthentication: no account');
      throw StateError('Belum sign-in Google  tidak bisa akses Drive.');
    }
    final headers = await account.authorizationClient.authorizationHeaders(
      driveScopes,
      promptIfNecessary: promptIfNecessary,
    );
    if (headers == null) {
      debugPrint('[CloudBackup] authorizationHeaders: null (no Drive scope)');
      throw StateError('Authorization Drive (drive.file) tidak didapat.');
    }
    debugPrint('[CloudBackup] drive auth client ready');
    return _DriveAuthClient(headers);
  }

  /// Minta authorization Drive secara interaktif  **hanya** dipanggil dari
  /// user gesture eksplisit (tap "Sign in with Google" di Settings), supaya
  /// consent screen (kalau perlu muncul) terasa jadi kelanjutan aksi user,
  /// bukan popup mendadak. Gagal di sini tidak boleh menggagalkan sign-in
  /// utama (greeting tetap jalan meski Drive belum ter-otorisasi)  caller
  /// wajib bungkus try/catch dan diamkan errornya.
  static Future<void> requestDriveAuthorizationInteractive() async {
    final client = await getDriveAuthClient(promptIfNecessary: true);
    client.close();
  }
}

class _DriveAuthClient extends http.BaseClient {
  _DriveAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
