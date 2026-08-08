# Prompt Claude Code — Audio Enhancement Otomatis (Best-Effort, Riset Dulu)

Baca `Architecture.md` § 7a dan `PRD.md` § 7 item 9 & § 11 sebelum mulai — fitur ini eksplisit ditandai **best-effort**, boleh disederhanakan atau ditunda kalau feasibility teknisnya jelek. Jangan paksa implementasi kalau ternyata butuh workaround berisiko tinggi (fork plugin, native code kompleks yang gampang rapuh).

## Langkah 1 — Riset feasibility (wajib sebelum coding penuh)

Cek versi `just_audio` yang dipakai project ini: apakah expose `androidAudioSessionId` (getter atau stream) dengan stabil dari `AudioPlayer`. Kalau ya, lanjut ke Langkah 2. Kalau tidak/tidak reliable, **berhenti, laporkan ke saya** dengan penjelasan kenapa tidak feasible + opsi alternatif kalau ada (misal versi `just_audio` lain yang expose ini, atau approach berbeda) — jangan lanjut coding di kondisi ini tanpa konfirmasi.

## Langkah 2 — Implementasi (kalau Langkah 1 feasible)

Tujuan: MP3 kualitas biasa/bitrate rendah tetap terdengar enak, otomatis aktif, **tanpa UI equalizer manual** (Beatfy tetap minimalist, tidak perlu screen setting audio terpisah untuk versi ini).

1. Buat platform channel kecil (native Kotlin) yang terima `audioSessionId` dari Dart, lalu attach 3 native Android audio effect (`android.media.audiofx`):
   - `LoudnessEnhancer` — normalisasi file yang terasa pelan, target moderat (jangan bikin terlalu keras/pecah).
   - `Equalizer` — preset ringan clarity/warmth (boost dikit di area yang bikin vokal/instrumen lebih jelas), bukan preset ekstrem.
   - `BassBoost` — ringan saja, MP3 bitrate rendah gampang distorsi kalau bass di-boost agresif.
2. Effect ini attach ulang tiap kali `audioSessionId` berubah (misal player di-reset), dan release dengan benar saat app/player di-dispose (jangan leak native resource).
3. Tidak ada toggle on/off di UI untuk versi ini — aktif otomatis untuk semua playback. (Kalau nanti Pann minta toggle manual, itu perubahan terpisah, belum sekarang.)

## QC (wajib pakai telinga asli, bukan cuma "kode jalan tanpa error")

- Tidak perlu checklist `Rules.md` § 4 penuh, tapi WAJIB: coba dengar minimal 3 lagu dengan kualitas source berbeda (kalau ada — bitrate rendah/hasil convert vs bitrate tinggi) di device nyata, pastikan tidak ada distorsi/pecah/terlalu berisik di volume normal. Kalau default preset yang dipakai kedengaran merusak audio (bukan memperbaiki), turunkan intensitasnya sebelum lapor selesai — jangan lapor selesai kalau kupingnya sendiri terasa tidak enak.
- Pastikan tidak ada crash/lag tambahan saat effect di-attach (terutama saat ganti lagu cepat/skip berturut-turut).

Laporkan di akhir: preset value yang dipakai (biar saya tahu seberapa agresif), dan hasil dengar-langsung tadi.
