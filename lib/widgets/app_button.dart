import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }
enum AppButtonSize { sm, md, lg, icon }

class AppButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool disabled;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.disabled = false,
    this.width,
    this.height,
    this.borderRadius,
  });

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
      case AppButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case AppButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
      case AppButtonSize.icon:
        return const EdgeInsets.all(6);
    }
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.sm:
        return 30;
      case AppButtonSize.md:
        return 38;
      case AppButtonSize.lg:
        return 46;
      case AppButtonSize.icon:
        return 28;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.sm:
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
      case AppButtonSize.md:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
      case AppButtonSize.lg:
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
      case AppButtonSize.icon:
        return const TextStyle(fontSize: 14);
    }
  }

  ButtonStyle _getButtonStyle() {
    switch (variant) {
      case AppButtonVariant.primary:
        return ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.muted;
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.mutedForeground;
            return AppColors.primaryForeground;
          }),
          overlayColor: WidgetStateProperty.all(AppColors.primaryForeground.withValues(alpha: 0.1)),
        );
      case AppButtonVariant.secondary:
        return ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.muted;
            return AppColors.secondary;
          }),
          foregroundColor: const WidgetStatePropertyAll(AppColors.foreground),
          overlayColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
        );
      case AppButtonVariant.outline:
        return ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: const WidgetStatePropertyAll(AppColors.foreground),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
          overlayColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
        );
      case AppButtonVariant.ghost:
        return ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: const WidgetStatePropertyAll(AppColors.foreground),
          overlayColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
        );
      case AppButtonVariant.destructive:
        return ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.muted;
            return AppColors.destructive;
          }),
          foregroundColor: const WidgetStatePropertyAll(AppColors.destructiveForeground),
          overlayColor: WidgetStateProperty.all(AppColors.destructiveForeground.withValues(alpha: 0.1)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? _getHeight(),
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: _getButtonStyle().copyWith(
          padding: WidgetStateProperty.all(_getPadding()),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(8))),
          textStyle: WidgetStateProperty.all(_getTextStyle()),
        ),
        child: child,
      ),
    );
  }
}
