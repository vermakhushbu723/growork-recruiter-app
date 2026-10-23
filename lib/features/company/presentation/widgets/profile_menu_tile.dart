import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/ui_kit.dart';

class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  /// Red title for actions like Logout.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.tintBlue;
    return SoftCard(
      onTap: onTap,
      radius: 9,
      padding: const EdgeInsets.fromLTRB(12, 5.5, 10, 5.5),
      child: Row(
        children: [
          IconBubble(
            icon: icon,
            color: color,
            size: 34,
            iconSize: 16,
            circle: false,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
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
          Icon(
            Icons.chevron_right_rounded,
            size: 15,
            color: context.textSubColor,
          ),
        ],
      ),
    );
  }
}
