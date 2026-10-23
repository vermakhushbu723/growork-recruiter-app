import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../utils/extensions.dart';
import 'animations/tap_scale.dart';
import 'ui_kit.dart';

/// Tinted icon + label button on the right of a tab header (same style as
/// the user app's "My Work" button).
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
        decoration: BoxDecoration(
          color: context.tagBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.accentColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: context.accentColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: context.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blue gradient banner with three ticks and a white CTA (same style as the
/// user app's "Start Freelancing" banner).
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.title,
    required this.message,
    required this.ctaLabel,
    required this.onTap,
    required this.icon,
    this.points = const [],
  });

  final String title;
  final String message;
  final String ctaLabel;
  final VoidCallback onTap;
  final IconData icon;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    Widget point(String text) => Container(
      margin: const EdgeInsets.only(bottom: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 7,
            color: Color(0xFF9FD3FF),
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 6),
          ),
        ],
      ),
    );

    return Container(
      height: 100,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3FA8), Color(0xFF1560D8), Color(0xFF3B8BF0)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 50,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 92,
            bottom: 14,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
          Positioned(
            right: 4,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final p in points) point(p)],
            ),
          ),
          const Positioned(
            right: 8,
            bottom: 6,
            child: Icon(Icons.eco_rounded, size: 20, color: Color(0xFF6BBC46)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 160, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 9.5,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: WhitePillButton(
                    label: ctaLabel,
                    height: 23,
                    fontSize: 9,
                    onTap: onTap,
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

/// Row of coloured pipeline counters (New 4 · Shortlisted 2 · …).
class PipelineStrip extends StatelessWidget {
  const PipelineStrip({super.key, required this.items});

  final List<({String label, int count, Color color, VoidCallback? onTap})>
  items;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  indent: 6,
                  endIndent: 6,
                  color: context.borderColor,
                ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: items[i].onTap,
                  child: Column(
                    children: [
                      Text(
                        '${items[i].count}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: items[i].color,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          items[i].label,
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            color: context.textSubColor,
                          ),
                        ),
                      ),
                    ],
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
