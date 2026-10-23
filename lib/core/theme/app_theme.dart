import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Central Material theme. Sizes follow the design mockups (360dp phone):
/// compact text, 9dp card radius, 40dp buttons, soft shadows.
/// Font: Inter, bundled in assets and registered in pubspec as `Inter`.
class AppTheme {
  AppTheme._();

  static const String _font = 'Inter';

  /// Navy used for headings in the mockups.
  static const Color _heading = Color(0xFF0F1B3D);

  /// Button blue from the mockups.
  static const Color _buttonBlue = Color(0xFF1A52B1);

  static TextTheme _textTheme(Color heading, Color main, Color sub) {
    TextStyle s(double size, FontWeight w, Color c, {double? h}) => TextStyle(
      fontFamily: _font,
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
    );
    return TextTheme(
      displayLarge: s(32, FontWeight.w800, heading),
      displayMedium: s(28, FontWeight.w800, heading),
      displaySmall: s(24, FontWeight.w800, heading),
      headlineLarge: s(22, FontWeight.w800, heading),
      headlineMedium: s(19, FontWeight.w800, heading),
      headlineSmall: s(16.5, FontWeight.w800, heading),
      titleLarge: s(14, FontWeight.w800, heading),
      titleMedium: s(12, FontWeight.w700, heading),
      titleSmall: s(11, FontWeight.w700, heading),
      bodyLarge: s(11.5, FontWeight.w400, main, h: 1.4),
      bodyMedium: s(10.5, FontWeight.w400, sub, h: 1.4),
      bodySmall: s(9.5, FontWeight.w400, sub, h: 1.35),
      labelLarge: s(11.5, FontWeight.w700, main),
      labelMedium: s(10, FontWeight.w600, main),
      labelSmall: s(9, FontWeight.w600, sub),
    );
  }

  static ThemeData get light => _build(
    brightness: Brightness.light,
    primary: AppColors.primary,
    button: _buttonBlue,
    bg: AppColors.bg,
    surface: AppColors.surface,
    border: AppColors.border,
    inputBorder: AppColors.inputBorder,
    heading: _heading,
    main: AppColors.textMain,
    sub: AppColors.textSub,
    hint: AppColors.textHint,
    tagBg: AppColors.jobTagBg,
    shadow: const Color(0xFF3B4A7A).withValues(alpha: 0.18),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    primary: AppColors.primaryLight,
    button: AppColors.primaryLight,
    bg: AppColors.bgDark,
    surface: AppColors.surfaceDark,
    border: AppColors.borderDark,
    inputBorder: AppColors.inputBorderDark,
    heading: AppColors.textMainDark,
    main: AppColors.textMainDark,
    sub: AppColors.textSubDark,
    hint: AppColors.textHintDark,
    tagBg: AppColors.jobTagBgDark,
    shadow: Colors.black.withValues(alpha: 0.5),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color button,
    required Color bg,
    required Color surface,
    required Color border,
    required Color inputBorder,
    required Color heading,
    required Color main,
    required Color sub,
    required Color hint,
    required Color tagBg,
    required Color shadow,
  }) {
    final isDark = brightness == Brightness.dark;
    final onButton = isDark ? Colors.black : Colors.white;
    final base = isDark ? const ColorScheme.dark() : const ColorScheme.light();
    final colorScheme = base.copyWith(
      primary: primary,
      onPrimary: onButton,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      error: AppColors.error,
      surface: surface,
      onSurface: main,
      onSurfaceVariant: sub,
      outline: inputBorder,
      outlineVariant: border,
      surfaceContainerHighest: tagBg,
    );
    final text = _textTheme(heading, main, sub);
    final radius9 = BorderRadius.circular(9);
    const buttonText = TextStyle(
      fontFamily: _font,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    OutlineInputBorder field(Color c, [double w = 1.1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _font,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: text,
      iconTheme: IconThemeData(color: heading, size: 20),
      visualDensity: VisualDensity.compact,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: heading,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 52,
        titleSpacing: 4,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          color: heading,
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: heading, size: 20),
        actionsIconTheme: IconThemeData(color: heading, size: 20),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: shadow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius9,
          side: isDark ? BorderSide(color: border) : BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: button,
          foregroundColor: onButton,
          disabledBackgroundColor: button.withValues(alpha: 0.4),
          disabledForegroundColor: onButton.withValues(alpha: 0.8),
          minimumSize: const Size.fromHeight(40),
          shape: RoundedRectangleBorder(borderRadius: radius9),
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: button,
          foregroundColor: onButton,
          minimumSize: const Size.fromHeight(40),
          shape: RoundedRectangleBorder(borderRadius: radius9),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.2),
          minimumSize: const Size.fromHeight(40),
          shape: RoundedRectangleBorder(borderRadius: radius9),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: buttonText.copyWith(fontSize: 11),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        hintStyle: TextStyle(fontFamily: _font, color: hint, fontSize: 11),
        labelStyle: TextStyle(fontFamily: _font, color: sub, fontSize: 11),
        errorStyle: const TextStyle(fontFamily: _font, fontSize: 9.5),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused) ? primary : sub,
        ),
        suffixIconColor: sub,
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        border: field(inputBorder),
        enabledBorder: field(inputBorder),
        focusedBorder: field(primary, 1.6),
        errorBorder: field(AppColors.error),
        focusedErrorBorder: field(AppColors.error, 1.6),
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? button : tagBg,
        ),
        labelStyle: TextStyle(
          fontFamily: _font,
          color: WidgetStateColor.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? onButton : primary,
          ),
          fontWeight: FontWeight.w600,
          fontSize: 9.5,
        ),
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: sub,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: border,
        tabAlignment: TabAlignment.fill,
        labelStyle: const TextStyle(
          fontFamily: _font,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: _font,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        iconColor: sub,
        minLeadingWidth: 22,
        horizontalTitleGap: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: heading,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 9.5,
          color: sub,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? button : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? button : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? button : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? button : sub,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: button,
        linearTrackColor: tagBg,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: border,
        dragHandleSize: const Size(36, 4),
        constraints: const BoxConstraints(maxWidth: double.infinity),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? surface : _heading,
        contentTextStyle: const TextStyle(
          fontFamily: _font,
          fontSize: 11,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF1E6FE8),
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: surface, width: 280),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
