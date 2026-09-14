# Prompt Claude Code  Restrukturisasi MainShell: Scaffold.bottomNavigationBar (Pola Planly)

**Ini menggantikan prompt sebelumnya (`prompt_fix_miniplayer_overlap.md`)  kalau itu belum dikerjakan, skip, kerjakan yang ini saja. Kalau sudah terlanjur dikerjakan (konstanta `AppSpacing.floatingNavClearance` sudah ditambah), hapus lagi, tidak dibutuhkan setelah fix ini.**

Baca `Architecture.md` § 3a (revisi 2026-08-08) untuk konteks lengkap. Pann minta arsitektur nav Beatfy disamakan persis dengan pola Planly (`planly-main/planly-main/lib/screens/main_shell.dart`): pakai slot `Scaffold.bottomNavigationBar` bawaan Flutter, bukan `Column` manual  supaya tidak perlu lagi menghitung/menebak padding clearance secara manual di tiap screen (`Library`, `Home`, dst), yang sudah beberapa kali kebukti gampang salah.

## Perubahan di `lib/screens/shell/main_shell.dart`

Restrukturisasi `_MainShellState.build()`:

**Sebelum** (pola saat ini): `Scaffold(body: SafeArea(child: Column([Expanded(IndexedStack(...)), MiniPlayer(), _BottomNavBar(...)])))`.

**Sesudah** (pola baru, meniru Planly):
```dart
Scaffold(
  backgroundColor: AppColors.canvas,
  extendBody: true, // body scroll penuh sampai bawah, transparan di balik bottomNavigationBar
  body: IndexedStack(
    index: _index,
    children: const [HomeScreen(), SearchScreen(), LibraryScreen(), PlaylistListScreen()],
  ),
  bottomNavigationBar: SafeArea(
    top: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MiniPlayer(),
        _BottomNavBar(currentIndex: _index, onTap: (index) => setState(() => _index = index)),
      ],
    ),
  ),
)
```

(Sesuaikan detail persis kalau ada perbedaan struktur terbaru di file  prinsip utamanya: `MiniPlayer`+`_BottomNavBar` pindah dari `Column` di `body` ke slot `bottomNavigationBar`, `extendBody: true` ditambahkan, `SafeArea` dipindah ke pembungkus `bottomNavigationBar` bukan `body` lagi karena `body` sekarang perlu extend penuh termasuk area system nav bar.)

**Hapus** komentar/logic `resizeToAvoidBottomInset: false` yang lama di Scaffold ini kalau sudah tidak relevan dengan struktur baru  evaluasi apakah masih dibutuhkan sama sekali dengan `bottomNavigationBar` slot (biasanya tidak, karena `bottomNavigationBar` sudah dikecualikan dari resize secara default oleh Flutter). Kalau ragu, test dulu behavior keyboard di tab Search & Playlist (form) tetap benar (nav+miniplayer masih tertutup keyboard seperti sebelumnya, bukan malah terdorong ke atas) sebelum memutuskan hapus atau tidak.

## Hapus padding manual yang sudah tidak dibutuhkan

Di `library_screen.dart`, `home_screen.dart` (dan cek `playlist_list_screen.dart`): kembalikan `padding` `ListView` yang tadinya besar (`AppSpacing.xxxl` atau konstanta clearance lain kalau sempat ditambah) ke nilai kecil wajar (`AppSpacing.md`/`AppSpacing.lg`)  cuma buat jarak visual estetika biasa, BUKAN lagi mencoba menghitung tinggi MiniPlayer/NavBar. Dengan `extendBody: true`, list yang scroll ke bawah akan otomatis terlihat "di balik" pill yang transparan, itu efek yang diinginkan (persis instruksi Pann: "jadikan transparan saja tapi tetap timbul bagian tabnya").

## QC wajib

- Scroll Library/Home sampai baris paling akhir, DENGAN dan TANPA lagu aktif (MiniPlayer showing/tidak)  pastikan baris terakhir tidak pernah ketutup permanen, dan terlihat natural "lewat di balik" pill transparan saat discroll (bukan ke-clip aneh).
- Cek Search & Playlist (form input)  pastikan keyboard masih berperilaku benar (nutupin nav+miniplayer seperti biasa, bukan mendorongnya ke atas keyboard)  ini area yang paling rawan regresi dari restrukturisasi Scaffold.
- Cek tap-tap semua 4 tab, mini player expand ke Now Playing, semua masih normal  restrukturisasi ini area sensitif (root shell), regresi kecil di sini bisa berdampak ke semua tab sekaligus.
