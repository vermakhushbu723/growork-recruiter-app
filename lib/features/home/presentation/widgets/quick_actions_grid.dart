import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/animations/fade_slide_up.dart';
import '../../../../core/widgets/ui_kit.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  static const _actions = [
    (
      icon: Icons.post_add_rounded,
      label: 'Post a Job',
      subtitle: 'Jobs & internships',
      route: RoutePaths.postJob,
      color: AppColors.tintBlue,
    ),
    (
      icon: Icons.laptop_rounded,
      label: 'Post Project',
      subtitle: 'Hire a freelancer',
      route: RoutePaths.postProject,
      color: AppColors.tintOrange,
    ),
    (
      icon: Icons.person_search_rounded,
      label: 'Find Talent',
      subtitle: 'Search profiles',
      route: RoutePaths.talentSearch,
      color: AppColors.tintGreen,
    ),
    (
      icon: Icons.event_note_rounded,
      label: 'Interviews',
      subtitle: 'Your schedule',
      route: RoutePaths.interviews,
      color: AppColors.tintPurple,
    ),
    (
      icon: Icons.handshake_rounded,
      label: 'Contracts',
      subtitle: 'Milestones & pay',
      route: RoutePaths.contracts,
      color: AppColors.tintTeal,
    ),
    (
      icon: Icons.insights_rounded,
      label: 'Analytics',
      subtitle: 'Hiring insights',
      route: RoutePaths.analytics,
      color: AppColors.tintRed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 7,
        mainAxisExtent: 82,
      ),
      itemBuilder: (context, index) {
        final action = _actions[index];
        return FadeSlideUp(
          index: index,
          stagger: const Duration(milliseconds: 55),
          offset: 18,
          child: SoftCard(
            radius: 10,
            padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
            onTap: () => context.push(action.route),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconBubble(
                      icon: action.icon,
                      color: action.color,
                      size: 38,
                      iconSize: 18,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: context.textSubColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: headingColor(context),
                  ),
                ),
                Text(
                  action.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    height: 1.3,
                    color: context.textSubColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
