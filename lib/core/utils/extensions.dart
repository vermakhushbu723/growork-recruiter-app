import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.of(this).size;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Theme-aware palette (use these instead of the light-only
  // AppColors.surface / border / text* so dark mode stays readable) ──
  Color get bgColor => isDark ? AppColors.bgDark : AppColors.bg;
  Color get surfaceColor => isDark ? AppColors.surfaceDark : AppColors.surface;
  Color get borderColor => isDark ? AppColors.borderDark : AppColors.border;
  Color get textMainColor =>
      isDark ? AppColors.textMainDark : AppColors.textMain;
  Color get textSubColor => isDark ? AppColors.textSubDark : AppColors.textSub;
  Color get textHintColor =>
      isDark ? AppColors.textHintDark : AppColors.textHint;
  Color get tagBgColor => isDark ? AppColors.jobTagBgDark : AppColors.jobTagBg;
  Color get accentColor => isDark ? AppColors.primaryLight : AppColors.primary;

  /// Very soft shadow that lifts cards off the background.
  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ]
      : [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ];

  /// Raised card look for custom containers (matches [Card] theme).
  BoxDecoration cardDecoration({double radius = 16}) => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: cardShadow,
  );

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

extension StringX on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

extension ApiActionX on BuildContext {
  /// Runs an API call. On failure shows the server's message and returns
  /// false; on success optionally shows [success] and returns true.
  Future<bool> runApi(Future<void> Function() action, {String? success}) async {
    try {
      await action();
      if (success != null && mounted) showSnackBar(success);
      return true;
    } catch (e) {
      if (mounted) showSnackBar(e.toString(), isError: true);
      return false;
    }
  }
}
