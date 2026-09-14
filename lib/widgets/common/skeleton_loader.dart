import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Shimmer skeleton primitive  Design.md § 12 ("Skeleton loading, bukan
/// spinner generik"). Base/highlight pakai `AppColors.surfaceMuted`/
/// `surfaceHover`, gradient band bergerak lewat [GradientTransform] (pola
/// sama seperti package `shimmer`, di-port manual biar tidak nambah
/// dependency baru).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.xs,
    this.circle = false,
  });

  final double? width;
  final double? height;
  final double radius;

  /// Art/avatar sekarang circular-first (Design.md § 5)  pakai ini alih-alih
  /// [radius] untuk skeleton yang merepresentasikan artwork/cover/avatar.
  final bool circle;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circle
                ? null
                : BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: const [
                AppColors.surfaceMuted,
                AppColors.surfaceHover,
                AppColors.surfaceMuted,
              ],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 3 - 1.5),
      0,
      0,
    );
  }
}

/// Skeleton bentuk [SongRow]  dipakai saat library scan / search / list
/// lagu lain sedang loading.
class SkeletonSongRow extends StatelessWidget {
  const SkeletonSongRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 48, height: 48, circle: true),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 96, height: 12),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const SkeletonBox(width: 32, height: 32, circle: true),
        ],
      ),
    );
  }
}

/// Skeleton bentuk `_PlaylistCard` (grid)  dipakai saat Playlist tab loading.
class SkeletonPlaylistCard extends StatelessWidget {
  const SkeletonPlaylistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AspectRatio(aspectRatio: 1, child: SkeletonBox(circle: true)),
        const SizedBox(height: AppSpacing.xs),
        const SkeletonBox(width: 80, height: 16),
        const SizedBox(height: AppSpacing.xxs),
        const SkeletonBox(width: 50, height: 10),
      ],
    );
  }
}

/// Skeleton bentuk `_HomeSongCard` (horizontal, Home tab).
class SkeletonHomeCard extends StatelessWidget {
  const SkeletonHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 128,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBox(width: 128, height: 128, circle: true),
          SizedBox(height: AppSpacing.xs),
          SkeletonBox(width: 100, height: 14),
          SizedBox(height: AppSpacing.xxs),
          SkeletonBox(width: 64, height: 12),
        ],
      ),
    );
  }
}
