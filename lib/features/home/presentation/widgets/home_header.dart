import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Greeting row at the top of the dashboard: avatar (opens the drawer),
/// greeting, name, company, notifications and saved-talent shortcuts.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.company,
    this.unread = 0,
  });

  final String userName;
  final String company;

  /// Unread notifications, shown as the bell badge.
  final int unread;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Row(
      children: [
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: UserAvatar(name: userName, size: 43),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  height: 1.25,
                  color: context.textSubColor,
                ),
              ),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16.5,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: headingColor(context),
                ),
              ),
              Text(
                "Let's hire great people for $company",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  height: 1.3,
                  color: context.textSubColor,
                ),
              ),
            ],
          ),
        ),
        CircleActionButton(
          icon: Icons.notifications_none_rounded,
          badge: unread,
          filled: false,
          size: 30,
          iconSize: 22,
          onTap: () => context.push(RoutePaths.notifications),
        ),
        const SizedBox(width: 18),
        CircleActionButton(
          icon: Icons.bookmark_border_rounded,
          filled: false,
          size: 30,
          iconSize: 22,
          onTap: () => context.push(RoutePaths.savedTalent),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
