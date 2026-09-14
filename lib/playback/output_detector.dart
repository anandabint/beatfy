// `AudioDeviceType` is the only API `audio_session` exposes for categorizing
// connected output devices; it's marked experimental by the package author
// but is stable enough for this general speaker/wired/bluetooth grouping.
// ignore_for_file: experimental_member_use

import 'package:audio_session/audio_session.dart';

/// Deteksi Bluetooth/wired output connect-disconnect  Architecture.md § 5.
///
/// Dibangun di atas `audio_session`, yang membungkus mekanisme standar
/// Android (`AudioManager` + broadcast `ACTION_AUDIO_BECOMING_NOISY`)  API
/// umum yang sama dipakai ExoPlayer/Media3 lewat
/// `setHandleAudioBecomingNoisy`, bukan logic device-specific.
class OutputDetector {
  OutputDetector([AudioSession? session])
    : _sessionFuture = Future.value(session ?? AudioSession.instance);

  final Future<AudioSession> _sessionFuture;

  /// Fires setiap kali output device (headset Bluetooth/wired) terputus 
  /// caller (AudioHandler) yang memutuskan mau auto-pause atau tidak.
  Stream<void> get onOutputDisconnected async* {
    final session = await _sessionFuture;
    yield* session.becomingNoisyEventStream;
  }

  /// Ringkasan output aktif saat ini, dipakai provider kalau UI mau
  /// menampilkan indikator kecil (Architecture.md § 5 poin 3). Tidak ada
  /// logic per-merek  cuma kategori umum dari [AudioDeviceType].
  Stream<ActiveOutput> get activeOutputStream async* {
    final session = await _sessionFuture;
    yield* session.devicesStream.map(_toActiveOutput);
  }

  ActiveOutput _toActiveOutput(Set<AudioDevice> devices) {
    final outputs = devices.where((d) => d.isOutput);
    final hasBluetooth = outputs.any(
      (d) =>
          d.type == AudioDeviceType.bluetoothA2dp ||
          d.type == AudioDeviceType.bluetoothSco,
    );
    if (hasBluetooth) return ActiveOutput.bluetooth;

    final hasWired = outputs.any(
      (d) =>
          d.type == AudioDeviceType.wiredHeadset ||
          d.type == AudioDeviceType.wiredHeadphones,
    );
    if (hasWired) return ActiveOutput.wired;

    return ActiveOutput.speaker;
  }
}

enum ActiveOutput { speaker, wired, bluetooth }
