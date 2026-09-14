# Prompt Claude Code  Fix Gap Keyboard Search (Round 2) + Pill Nav Transparent

Dua item, screenshot Pann sebagai bukti (lihat lampiran chat)  kedua bug sudah pernah "difix" sebelumnya tapi ternyata belum tuntas.

## 1. Gap kosong di atas keyboard (Search)  audit ulang lebih menyeluruh

Fix sesi lalu (bikin bottom padding list jadi conditional saat `viewInsets.bottom > 0`) ternyata belum sepenuhnya menghilangkan gap-nya  screenshot Pann masih nunjukkan ruang kosong antara list hasil pencarian dan keyboard. Kali ini jangan cuma tweak angka padding lagi, audit semua layer yang mungkin nyisain ruang:

1. Cek struktur widget Search screen dari luar ke dalam: `Scaffold` → `Column`/`Stack` → `Expanded`/`Flexible` yang membungkus list hasil → `ListView` itu sendiri. Cari SEMUA tempat yang punya `padding`, `SizedBox` fixed height, atau constraint yang tidak menyusut saat keyboard muncul.
2. **Bedakan dua kemungkinan berbeda** (penting, jangan disamakan): (a) padding/reservasi ruang untuk bottom-nav yang seharusnya hilang saat keyboard terbuka  ini bug, harus dihilangkan total saat `viewInsets.bottom > 0`. (b) `Expanded` yang wajar kosong di bawah karena hasil pencarian memang sedikit (list pendek, tidak sampai memenuhi layar)  ini BUKAN bug, itu perilaku normal. Pastikan fix yang diterapkan menghilangkan (a) sepenuhnya, dan kalau ternyata sisa gap yang terlihat di screenshot itu murni kasus (b), laporkan itu ke saya secara eksplisit dengan bukti (misal jumlah hasil pencarian saat itu)  jangan diklaim sebagai "sudah fix" kalau ternyata itu masalah berbeda yang butuh keputusan lain.
3. Kalau perlu, pakai `debugPaintSizeEnabled` atau Flutter Inspector buat lihat persis widget mana yang menghasilkan ruang kosong itu, jangan cuma tebak dari baca kode.

## 2. Pill nav (bottom nav + mini player)  hilangkan background kotak di belakangnya

Baca `Design.md` § 7 (Bottom nav & Mini player, revisi 2026-08-08). Bug: ada background berbentuk kotak/persegi yang kelihatan di belakang bentuk pill yang bulat (walau warnanya gelap/mirip canvas, tetap kelihatan sebagai bentuk berbeda dari pill-nya sendiri, terutama di sekitar sudut). Root cause yang paling umum untuk pola ini: wrapper luar (`Material`/`BottomAppBar`/slot `Scaffold.bottomNavigationBar`) punya warna fill sendiri yang default tidak transparent, melukis kotak penuh selebar layar, sementara pill yang terlihat cuma dekorasi `BoxDecoration`/`borderRadius` di dalamnya.

Fix: pastikan wrapper terluar (apapun bentuknya  `Material`, `Container`, atau slot Scaffold) di-set `color: Colors.transparent` (atau `Material(type: MaterialType.transparency)` kalau butuh tetap `Material` untuk ink/splash effect). HANYA `Container` pill itu sendiri (dengan `BoxDecoration` + `borderRadius: BorderRadius.circular(999)`/pill) yang boleh punya warna fill. Terapkan di kedua tempat  bottom nav DAN mini player (cek apakah mini player punya struktur serupa, kemungkinan besar sama karena dibangun dengan pola visual yang sama).

## QC

Device nyata wajib untuk kedua item  screenshot before/after, dan untuk item 1 khususnya coba dengan query yang hasilnya BANYAK (list panjang, penuh layar) DAN query yang hasilnya sedikit (list pendek) supaya kelihatan jelas mana yang bug mana yang perilaku normal.
