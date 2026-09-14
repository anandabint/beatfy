# Prompt untuk Claude Code  Now Playing: Hilangkan Thumb Slider + Turunkan Spacing Konten Bawah Art

Dua perubahan di `NowPlayingScreen`, keduanya khusus area di bawah album art  **posisi/ukuran album art (bulatan) JANGAN diubah**, sudah benar sesuai revisi sebelumnya.

## 1. Hilangkan bulatan/thumb di kedua slider

Berlaku untuk **slider progress/durasi lagu** dan **slider volume** (dua-duanya). Sekarang ada bulatan (thumb/knob) yang muncul di ujung posisi slider  Pann minta itu dihilangkan, cukup track + fill warna lime aja tanpa knob bulat.

Cara di Flutter (`SliderTheme`/`SliderThemeData` yang dipakai kedua slider ini):

```dart
SliderTheme(
  data: SliderThemeData(
    thumbShape: SliderComponentShape.noThumb,
    overlayShape: SliderComponentShape.noThumb, // hilangkan juga overlay ripple saat di-tap/drag
    trackHeight: ..., // pertahankan sesuai desain sekarang
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: ..., // pertahankan sesuai desain sekarang
  ),
  child: Slider(...),
)
```

Catatan: tanpa thumb visual, `Slider` tetap bisa di-drag/tap seperti biasa (area gesture-nya tidak hilang, cuma indikator visualnya). Kalau nanti ternyata jadi susah di-drag karena target area kecil tanpa thumb, boleh perbesar `trackHeight` sedikit supaya tetap enak disentuh  improvisasi kecil ini boleh jalan tanpa nanya dulu.

## 2. Turunkan spacing dari judul lagu sampai slider volume

Blok konten dari **judul lagu** sampai **slider volume** (judul, artis, baris lirik kalau ada, progress bar, tombol transport, slider volume  semua yang di bawah art) posisinya digeser turun sedikit  tambah jarak/padding antara **art** dan **judul lagu** (elemen pertama di blok ini), TANPA mengubah posisi/ukuran art itu sendiri. Cukup tambah `SizedBox`/padding di titik transisi art → judul, nilai pastinya sesuaikan secara visual (mulai dari nambah ~12-16px dari spacing yang sekarang, lalu adjust sampai proporsinya pas).

## QC

Tidak perlu checklist QC device dari `Rules.md`  Pann cek visual sendiri langsung. Build, pastikan `flutter analyze` bersih, kasih screenshot before/after kalau bisa.
