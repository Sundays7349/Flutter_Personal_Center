import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final Widget? header;
  final Widget? footer;
  final double? width;
  final double? height;
  final bool showBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.header,
    this.footer,
    this.width,
    this.height,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorderRadius = borderRadius ?? BorderRadius.circular(12);
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: cardBorderRadius,
        border: showBorder ? Border.all(color: AppColors.border) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header ?? const SizedBox.shrink(),
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
          footer ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class AppCardHeader extends StatelessWidget {
  final Widget title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AppCardHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: DefaultTextStyle(
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
            child: title,
          )),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class AppCardTitle extends StatelessWidget {
  final Widget child;
  final TextStyle? style;

  const AppCardTitle({super.key, required this.child, this.style});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
      child: child,
    );
  }
}
