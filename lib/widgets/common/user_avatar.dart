import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_providers.dart';

/// Avatar user  Design.md § 7 "Avatar/foto profil". 3 state, dipakai di
/// header Home dan Settings:
///
/// (a) Sign-in + akun Google punya foto → foto asli (`photoUrl`, di-cache
///     di `UserProfileCache` saat sign-in  Architecture.md § 4c, tidak ada
///     call live di sini). Gagal load → fallback ke state (b) lewat
///     `Image.network.errorBuilder` (Flutter re-render otomatis, tidak
///     butuh state manual).
/// (b) Sign-in tapi akun tidak punya foto → placeholder netral (icon
///     person generik, tint lime).
/// (c) Belum sign-in → **bukan** placeholder yang mirip foto profil  icon
///     outline tanpa background bulat solid, supaya user tidak salah kira
///     sudah login.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    if (profile == null) return _NotSignedInAvatar(size: size);

    final photoUrl = profile.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      return _PlaceholderAvatar(size: size);
    }

    return ClipOval(
      child: Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _PlaceholderAvatar(size: size),
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: size * 0.5,
      ),
    );
  }
}

class _NotSignedInAvatar extends StatelessWidget {
  const _NotSignedInAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairline, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline_rounded,
        color: AppColors.stone,
        size: size * 0.5,
      ),
    );
  }
}
