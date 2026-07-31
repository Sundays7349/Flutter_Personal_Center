import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../theme/app_theme.dart';

String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

DateTime? parseDate(String? text) {
  if (text == null || text.isEmpty) return null;
  try {
    return DateTime.parse(text);
  } catch (_) {
    return null;
  }
}

class AppDatePickerFormField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool autoToday;

  const AppDatePickerFormField({
    super.key,
    this.label,
    this.hintText,
    required this.controller,
    this.onChanged,
    this.width,
    this.padding,
    this.firstDate,
    this.lastDate,
    this.autoToday = true,
  });

  @override
  State<AppDatePickerFormField> createState() => _AppDatePickerFormFieldState();
}

class _AppDatePickerFormFieldState extends State<AppDatePickerFormField> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller;
    if (widget.autoToday && _internalController.text.isEmpty) {
      _internalController.text = formatDate(DateTime.now());
      widget.onChanged?.call(_internalController.text);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final currentDate = parseDate(_internalController.text) ?? DateTime.now();
    final firstDate = widget.firstDate ?? DateTime(2000, 1, 1);
    final lastDate = widget.lastDate ?? DateTime(2100, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.foreground,
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          child: Localizations(
            locale: const Locale('zh', 'CN'),
            delegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      final formatted = formatDate(picked);
      _internalController.text = formatted;
      widget.onChanged?.call(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final input = TextFormField(
      controller: _internalController,
      readOnly: true,
      style: const TextStyle(fontSize: 14, color: AppColors.foreground),
      decoration: InputDecoration(
        hintText: widget.hintText ?? '选择日期',
        hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
        filled: true,
        fillColor: AppColors.background,
        suffixIcon: const Icon(Icons.calendar_today, size: 18, color: AppColors.mutedForeground),
        contentPadding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      onTap: () => _selectDate(context),
    );

    if (widget.label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.label!,
              style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
            ),
          ),
          widget.width != null ? SizedBox(width: widget.width, child: input) : input,
        ],
      );
    }

    return widget.width != null ? SizedBox(width: widget.width, child: input) : input;
  }
}
