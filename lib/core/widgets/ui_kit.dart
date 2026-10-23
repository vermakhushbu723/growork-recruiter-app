import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../utils/extensions.dart';
import 'animations/tap_scale.dart';

// Sizes in this file are measured from the design mockups (360dp-wide phone).

/// Dark navy used for headings in the mockups.
const Color kHeadingColor = Color(0xFF0F1B3D);

/// Button blue from the mockups ("View Job", selected chips).
const Color kButtonBlue = Color(0xFF1A52B1);

Color headingColor(BuildContext context) =>
    context.isDark ? AppColors.textMainDark : kHeadingColor;

/// Large page title + grey subtitle used at the top of every tab screen.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.onBack,
    this.titleSize = 19,
    this.subtitleSize = 10.5,
  });

  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onBack;
  final double titleSize;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (onBack != null) ...[
          InkResponse(
            onTap: onBack,
            radius: 20,
            child: Padding(
              padding: EdgeInsets.only(bottom: titleSize * 0.7),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: headingColor(context),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: titleSize,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: headingColor(context),
                ),
              ),
              if (subtitleWidget != null || subtitle != null) ...[
                const SizedBox(height: 1),
                subtitleWidget ??
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: subtitleSize,
                        color: context.textSubColor,
                      ),
                    ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Very soft card shadow matching the mockups.
List<BoxShadow> softShadow(BuildContext context) => context.isDark
    ? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ]
    : [
        BoxShadow(
          color: const Color(0xFF3B4A7A).withValues(alpha: 0.07),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];

/// White, softly shadowed card. Tappable when [onTap] is given.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.radius = 9,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.surfaceColor,
        borderRadius: BorderRadius.circular(radius),
        border: context.isDark ? Border.all(color: context.borderColor) : null,
        boxShadow: softShadow(context),
      ),
      child: child,
    );
    return onTap == null ? card : TapScale(onTap: onTap, child: card);
  }
}

/// Search field + filter button row.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilter,
    this.solidFilter = false,
    this.showFilterDot = false,
    this.bordered = false,
    this.height = 36,
    this.fontSize = 9.5,
    this.insetFilter = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilter;

  /// Solid blue filter button (Jobs/Freelance) vs. light tinted (Home/Chat).
  final bool solidFilter;
  final bool showFilterDot;

  /// Visible outline around the field (Freelance) vs. borderless shadow.
  final bool bordered;
  final double height;
  final double fontSize;

  /// White card with a tinted square inside (Home) instead of a flat tint.
  final bool insetFilter;

  @override
  Widget build(BuildContext context) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: bordered
          ? BorderSide(
              color: context.isDark
                  ? AppColors.inputBorderDark
                  : const Color(0xFFDDE2EC),
            )
          : BorderSide.none,
    );
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: softShadow(context),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  color: context.textMainColor,
                ),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: hint,
                  hintMaxLines: 1,
                  isDense: true,
                  hintStyle: GoogleFonts.inter(
                    color: context.textHintColor,
                    fontSize: fontSize,
                  ),
                  fillColor: context.surfaceColor,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: context.textSubColor,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 20,
                  ),
                  // Centre the text vertically and fill the whole bar height.
                  contentPadding: EdgeInsets.symmetric(
                    vertical: (height - 13) / 2,
                  ),
                  border: outline,
                  enabledBorder: outline,
                  focusedBorder: outline.copyWith(
                    borderSide: BorderSide(
                      color: context.accentColor,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          TapScale(
            onTap: onFilter,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: height,
                  height: height,
                  padding: EdgeInsets.all(insetFilter ? 5 : 0),
                  decoration: BoxDecoration(
                    color: solidFilter
                        ? kButtonBlue
                        : insetFilter
                        ? context.surfaceColor
                        : context.tagBgColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: softShadow(context),
                  ),
                  child: Container(
                    decoration: insetFilter
                        ? BoxDecoration(
                            color: context.tagBgColor,
                            borderRadius: BorderRadius.circular(6),
                          )
                        : null,
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: solidFilter ? Colors.white : context.accentColor,
                    ),
                  ),
                ),
                if (showFilterDot)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.tintRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded selectable chip: solid blue when selected, tinted otherwise.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
    this.badge,
    this.height = 23,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  /// Tint for the unselected state; defaults to the brand blue.
  final Color? color;
  final IconData? icon;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.accentColor;
    final fg = selected ? Colors.white : tint;
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: selected
              ? kButtonBlue
              : tint.withValues(alpha: context.isDark ? 0.18 : 0.09),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                color: fg,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 5),
              Container(
                width: 11,
                height: 11,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.tintRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal scroller for [PillChip]s that bleeds to the screen edge.
class ChipScroller extends StatelessWidget {
  const ChipScroller({super.key, required this.children, this.padding = 13});

  final List<Widget> children;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: padding),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Small tinted label, e.g. "Remote", "Recruiter", "Mid Level".
class TintTag extends StatelessWidget {
  const TintTag(
    this.label, {
    super.key,
    required this.color,
    this.icon,
    this.fontSize = 8,
    this.height = 15,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final double fontSize;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Neutral grey skill chip ("React", "TypeScript").
class SkillChip extends StatelessWidget {
  const SkillChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFEFF1F7),
        borderRadius: BorderRadius.circular(100),
      ),
      // widthFactor keeps the chip as wide as its text inside a Wrap.
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 8, color: context.textSubColor),
        ),
      ),
    );
  }
}

/// Icon inside a soft tinted circle / rounded square.
class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    required this.color,
    this.size = 34,
    this.circle = true,
    this.iconSize,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool circle;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.2 : 0.12),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.27),
      ),
      child: Icon(icon, color: color, size: iconSize ?? size * 0.47),
    );
  }
}

/// Round white button with optional red count badge (header actions).
class CircleActionButton extends StatelessWidget {
  const CircleActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge = 0,
    this.size = 31,
    this.iconSize = 15,
    this.filled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  final double size;
  final double iconSize;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: filled
                ? BoxDecoration(
                    color: context.surfaceColor,
                    shape: BoxShape.circle,
                    boxShadow: softShadow(context),
                  )
                : null,
            child: Icon(icon, size: iconSize, color: headingColor(context)),
          ),
          if (badge > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 13,
                height: 13,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5252A),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.surfaceColor, width: 1),
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Section title with an optional trailing widget (See all / Sort by).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: headingColor(context),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// "Sort by Latest ⌄" control.
class SortByButton extends StatelessWidget {
  const SortByButton({super.key, this.value, this.onTap});

  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort by',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: context.textSubColor,
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 9),
              Text(
                value!,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: headingColor(context),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: headingColor(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blue "View Job →" / "View Details →" button.
class ArrowButton extends StatelessWidget {
  const ArrowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 26,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: kButtonBlue,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

/// White pill with arrow, used on blue banners ("View Wallet →").
class WhitePillButton extends StatelessWidget {
  const WhitePillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 23,
    this.fontSize = 9.5,
  });

  final String label;
  final VoidCallback onTap;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: height * 0.55),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.brandNavy,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.brandNavy,
              size: fontSize + 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand-style logo tile for known companies; initials for anyone else.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({
    super.key,
    required this.name,
    this.size = 60,
    this.circle = false,
  });

  final String name;
  final double size;
  final bool circle;

  static const _palette = [
    Color(0xFF0B3D91),
    Color(0xFF2E1A6B),
    Color(0xFF16794C),
    Color(0xFF7B3FE4),
    Color(0xFFE5484D),
    Color(0xFF0E9384),
    Color(0xFFF08A12),
  ];

  @override
  Widget build(BuildContext context) {
    final key = name.toLowerCase();
    final radius = circle
        ? BorderRadius.circular(size)
        : BorderRadius.circular(size * 0.19);

    Widget tile({
      required Color bg,
      required Widget child,
      bool border = false,
    }) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: border ? Border.all(color: const Color(0xFFE6E9F0)) : null,
      ),
      child: child,
    );

    if (key.startsWith('google')) {
      return tile(
        bg: Colors.white,
        border: true,
        child: ShaderMask(
          shaderCallback: (r) => const SweepGradient(
            colors: [
              Color(0xFFEA4335),
              Color(0xFFFBBC05),
              Color(0xFF34A853),
              Color(0xFF4285F4),
              Color(0xFFEA4335),
            ],
          ).createShader(r),
          child: Text(
            'G',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: size * 0.55,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
    if (key.startsWith('figma') || key.startsWith('creative labs')) {
      final d = size * 0.17;
      Widget dot(Color c, {BorderRadius? r}) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: c,
          borderRadius: r ?? BorderRadius.circular(d),
        ),
      );
      final left = BorderRadius.horizontal(left: Radius.circular(d));
      return tile(
        bg: const Color(0xFF111111),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                dot(const Color(0xFFF24E1E), r: left),
                dot(
                  const Color(0xFFFF7262),
                  r: BorderRadius.horizontal(right: Radius.circular(d)),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                dot(const Color(0xFFA259FF), r: left),
                dot(const Color(0xFF1ABCFE)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                dot(
                  const Color(0xFF0ACF83),
                  r: BorderRadius.only(
                    topLeft: Radius.circular(d),
                    bottomLeft: Radius.circular(d),
                    bottomRight: Radius.circular(d),
                  ),
                ),
                SizedBox(width: d),
              ],
            ),
          ],
        ),
      );
    }
    if (key.startsWith('microsoft')) {
      final q = size * 0.2;
      Widget sq(Color c) => Container(width: q, height: q, color: c);
      return tile(
        bg: Colors.white,
        border: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                sq(const Color(0xFFF25022)),
                SizedBox(width: q * 0.12),
                sq(const Color(0xFF7FBA00)),
              ],
            ),
            SizedBox(height: q * 0.12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                sq(const Color(0xFF00A4EF)),
                SizedBox(width: q * 0.12),
                sq(const Color(0xFFFFB900)),
              ],
            ),
          ],
        ),
      );
    }
    if (key.startsWith('amazon')) {
      return tile(
        bg: Colors.white,
        border: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'a',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: size * 0.5,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              width: size * 0.38,
              height: size * 0.07,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9900),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ],
        ),
      );
    }
    if (key.startsWith('apple')) {
      return tile(
        bg: Colors.white,
        border: true,
        child: Icon(Icons.apple, size: size * 0.6, color: Colors.black),
      );
    }
    if (key.startsWith('startupx')) {
      return tile(
        bg: const Color(0xFF0B1640),
        child: Text(
          'SX',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    if (key.startsWith('subkamyaab')) {
      return tile(
        bg: const Color(0xFF1B1F1A),
        child: Text(
          'JS',
          style: GoogleFonts.inter(
            color: const Color(0xFF6CC24A),
            fontSize: size * 0.32,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    if (key.startsWith('greenleaf')) {
      return tile(
        bg: const Color(0xFF16794C),
        child: Icon(Icons.eco_rounded, color: Colors.white, size: size * 0.5),
      );
    }
    if (key.startsWith('quickie') || key.contains('flutter')) {
      return tile(
        bg: const Color(0xFFE3F0FD),
        child: FlutterLogo(size: size * 0.55),
      );
    }
    if (key.startsWith('pixelcraft')) {
      return tile(
        bg: Colors.white,
        border: true,
        child: Icon(
          Icons.palette_rounded,
          color: const Color(0xFFE5484D),
          size: size * 0.5,
        ),
      );
    }

    final words = name
        .replaceAll(RegExp(r'[^A-Za-z ]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : (words.length == 1 || key.contains(' - ') || key.contains('('))
        ? words.first.substring(0, 1).toUpperCase()
        : (words[0][0] + words[1][0]).toUpperCase();
    final bg =
        _palette[name.codeUnits.fold(0, (a, b) => a + b) % _palette.length];
    return tile(
      bg: bg,
      child: Text(
        initials.length > 2 ? initials.substring(0, 2) : initials,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: size * (initials.length > 1 ? 0.36 : 0.42),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Circular user avatar: gradient with initials (photo when one exists).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.size = 42,
    this.ringColor,
    this.ringWidth = 2,
  });

  final String name;
  final double size;
  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringColor == null ? 0 : ringWidth),
      decoration: BoxDecoration(color: ringColor, shape: BoxShape.circle),
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB38A), Color(0xFFE5677A)],
          ),
        ),
        child: Text(
          initial,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Coloured icon tile + title/subtitle + chevron: the row used on Profile,
/// Settings and every list-style page.
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final VoidCallback? onTap;

  /// Replaces the chevron (e.g. a Switch or a value label).
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? AppColors.error : (color ?? AppColors.tintBlue);
    return SoftCard(
      onTap: onTap,
      radius: 9,
      padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 34),
        child: Row(
          children: [
            IconBubble(
              icon: icon,
              color: tint,
              size: 34,
              iconSize: 16,
              circle: false,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: destructive
                          ? AppColors.error
                          : headingColor(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.3,
                        color: context.textSubColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 15,
                  color: context.textSubColor,
                ),
          ],
        ),
      ),
    );
  }
}

/// Section heading above a group of cards ("Account", "Appearance").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: headingColor(context),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// White bar pinned to the bottom of a page holding the main action(s).
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

/// Standard layout inside a modal bottom sheet: title + options.
class SheetBody extends StatelessWidget {
  const SheetBody({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          14 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: headingColor(context),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 10, color: context.textSubColor),
              ),
            ],
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// One tappable row inside [SheetBody]; shows a tick when [selected].
class SheetOption extends StatelessWidget {
  const SheetOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : context.accentColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          children: [
            IconBubble(icon: icon, color: color, size: 32, iconSize: 15),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: destructive ? AppColors.error : headingColor(context),
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

/// Blue gradient hero card used at the top of Wallet-style pages.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF023DA3), Color(0xFF0B4CC0), Color(0xFF0A3C9E)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Label + value pair in a soft card (stats rows).
class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            IconBubble(
              icon: icon!,
              color: color ?? AppColors.tintBlue,
              size: 30,
              iconSize: 14,
            ),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: context.textSubColor),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: headingColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Labelled text field matching the mockup style (label above the field).
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.initialValue,
    this.validator,
    this.obscureText = false,
    this.suffix,
    this.onChanged,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? initialValue;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: headingColor(context),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(fontSize: 11, color: context.textMainColor),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(icon, size: 17),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
