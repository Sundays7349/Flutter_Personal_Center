import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget? label;
  final double size;

  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    final checkbox = SizedBox(
      width: size,
      height: size,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );

    if (label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          checkbox,
          const SizedBox(width: 8),
          label!,
        ],
      );
    }

    return checkbox;
  }
}

class AppProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const AppProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: backgroundColor ?? AppColors.muted,
        valueColor: AlwaysStoppedAnimation(color ?? AppColors.primary),
      ),
    );
  }
}
