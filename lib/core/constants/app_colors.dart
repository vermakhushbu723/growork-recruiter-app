import 'package:flutter/material.dart';

/// Single source of truth for every color in the app, taken from the
/// Subkamyaab logo (blue "S", green leaf, orange figure & star).
/// Change a value here and it updates on every screen.
class AppColors {
  AppColors._();

  // ── Logo palette ────────────────────────────────────────
  static const Color brandNavy = Color(0xFF032C73); // "sub" wordmark
  static const Color brandBlue = Color(0xFF0B4DA2); // S body
  static const Color brandSky = Color(0xFF1FA6E6); // S highlight
  static const Color brandTeal = Color(0xFF02605A); // S/leaf fold
  static const Color brandGreen = Color(0xFF0E8A55); // "kamyaab" wordmark
  static const Color brandLime = Color(0xFF6BBC46); // leaf highlight
  static const Color brandOrange = Color(0xFFFF9619); // figure
  static const Color brandAmber = Color(0xFFFEA817); // star
  static const Color brandOrangeDeep = Color(0xFFF26A0F); // figure shadow

  // ── Brand roles ─────────────────────────────────────────
  static const Color primary = brandBlue;
  static const Color primaryDark = brandNavy;
  static const Color primaryLight = brandSky;
  static const Color secondary = brandGreen;
  static const Color accent = brandOrange;
  static const Color accentBg = Color(0xFFFFF3E2);

  // ── Backgrounds / Surfaces ─────────────────────────────
  static const Color bg = Color(0xFFF6F7FC); // soft blue-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEDEFF5);
  static const Color inputBg = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFDCE1EB);

  /// Soft pink-grey tint used for the raised-card shadow.
  static const Color shadow = Color(0xFF4A5A85);

  // ── Dark mode surfaces ──────────────────────────────────
  static const Color bgDark = Color(0xFF0F1622);
  static const Color surfaceDark = Color(0xFF18212F);
  static const Color borderDark = Color(0xFF2A3546);
  static const Color inputBgDark = Color(0xFF1E2938);
  static const Color inputBorderDark = Color(0xFF3D4B60);
  static const Color jobTagBgDark = Color(0xFF1C2D47);

  // ── Text ────────────────────────────────────────────────
  static const Color textMain = Color(0xFF14213D);
  static const Color textSub = Color(0xFF5B6475);
  static const Color textHint = Color(0xFF959DAB);
  static const Color textMainDark = Color(0xFFF2F4F8);
  static const Color textSubDark = Color(0xFFB2BAC7);
  static const Color textHintDark = Color(0xFF7D8696);

  // ── Status / Tag ────────────────────────────────────────
  static const Color jobTagBg = Color(0xFFE6F0FB);
  static const Color jobTagTxt = brandBlue;
  static const Color remoteBg = Color(0xFFE5F5EC);
  static const Color remoteTxt = brandGreen;
  static const Color urgentBg = Color(0xFFFFEDE0);
  static const Color urgentTxt = Color(0xFFD9530B);

  // ── Accent tints used by icons, tags and chips ─────────
  static const Color tintBlue = Color(0xFF1E6FE8);
  static const Color tintOrange = Color(0xFFF08A12);
  static const Color tintGreen = Color(0xFF12A15E);
  static const Color tintPurple = Color(0xFF7B3FE4);
  static const Color tintRed = Color(0xFFE5484D);
  static const Color tintTeal = Color(0xFF0E9384);
  static const Color mint = Color(0xFFBDF2D8);

  // ── Semantic ────────────────────────────────────────────
  static const Color success = brandGreen;
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = brandAmber;
  static const Color info = brandSky;

  // ── Gradients ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandNavy, brandBlue, brandSky],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandTeal, brandGreen, brandLime],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandOrangeDeep, brandOrange, brandAmber],
  );

  /// Blue → green sweep of the logo's "S".
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, brandSky, brandGreen],
  );
}
