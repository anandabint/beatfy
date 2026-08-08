import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';

/// Horizontal scroll filter pill row — Design.md § 7: active pill filled
/// lime, dipakai di Home dan Library (label beda per konteks).
class FilterPillRow<T> extends StatelessWidget {
  const FilterPillRow({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<T> values;
  final Map<T, String> labels;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: values.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final value = values[index];
          final active = value == selected;
          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(value);
            },
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[value]!,
                style: AppTextTheme.labelMedium.copyWith(
                  color: active ? Colors.black : AppColors.ash,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
