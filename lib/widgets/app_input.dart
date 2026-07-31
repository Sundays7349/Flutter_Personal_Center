import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppInput extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool filled;
  final bool readOnly;

  const AppInput({
    super.key,
    this.label,
    this.hintText,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.padding,
    this.filled = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final input = TextFormField(
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 14, color: AppColors.foreground),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
        filled: filled,
        fillColor: AppColors.background,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );

    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label!,
              style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
            ),
          ),
          width != null ? SizedBox(width: width, child: input) : input,
        ],
      );
    }

    return width != null ? SizedBox(width: width, child: input) : input;
  }
}

class AppTextarea extends StatelessWidget {
  final String? hintText;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int minLines;
  final double? width;
  final bool readOnly;

  const AppTextarea({
    super.key,
    this.hintText,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.maxLines = 3,
    this.minLines = 3,
    this.width,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final input = TextFormField(
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 14, color: AppColors.foreground),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );

    return width != null ? SizedBox(width: width, child: input) : input;
  }
}
