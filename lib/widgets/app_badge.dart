import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppBadgeVariant { default_, secondary, outline, destructive, success, warning }

class AppBadge extends StatelessWidget {
  final Widget child;
  final AppBadgeVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const AppBadge({
    super.key,
    required this.child,
    this.variant = AppBadgeVariant.default_,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? _getBackgroundColor();
    final effectiveFgColor = foregroundColor ?? _getForegroundColor();
    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 2);

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(6),
        border: variant == AppBadgeVariant.outline
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: effectiveFgColor,
          fontSize: fontSize ?? 11,
          fontWeight: FontWeight.w500,
        ),
        child: child,
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case AppBadgeVariant.default_:
        return AppColors.primary;
      case AppBadgeVariant.secondary:
        return AppColors.secondary;
      case AppBadgeVariant.outline:
        return Colors.transparent;
      case AppBadgeVariant.destructive:
        return AppColors.destructive;
      case AppBadgeVariant.success:
        return AppColors.success;
      case AppBadgeVariant.warning:
        return AppColors.warning;
    }
  }

  Color _getForegroundColor() {
    switch (variant) {
      case AppBadgeVariant.default_:
        return AppColors.primaryForeground;
      case AppBadgeVariant.secondary:
        return AppColors.secondaryForeground;
      case AppBadgeVariant.outline:
        return AppColors.foreground;
      case AppBadgeVariant.destructive:
        return AppColors.destructiveForeground;
      case AppBadgeVariant.success:
        return AppColors.successForeground;
      case AppBadgeVariant.warning:
        return AppColors.warningForeground;
    }
  }
}
