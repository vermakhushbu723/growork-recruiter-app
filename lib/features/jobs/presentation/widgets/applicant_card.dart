import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/job_post_model.dart';

Color matchColor(int score) => score >= 85
    ? AppColors.tintGreen
    : score >= 70
    ? AppColors.tintOrange
    : AppColors.tintRed;

/// One application in the hiring pipeline.
class ApplicantCard extends StatelessWidget {
  const ApplicantCard({
    super.key,
    required this.applicant,
    required this.onTap,
    this.jobTitle,
    this.onShortlist,
    this.onMessage,
  });

  final Applicant applicant;
  final VoidCallback onTap;

  /// Shown when listing applicants across all jobs.
  final String? jobTitle;
  final VoidCallback? onShortlist;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final a = applicant;
    final sub = GoogleFonts.inter(fontSize: 8.5, color: context.textSubColor);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(11, 9, 9, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(name: a.name, size: 40),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: headingColor(context),
                      ),
                    ),
                    Text(
                      jobTitle == null
                          ? '${a.headline} · ${a.experience}'
                          : 'Applied for $jobTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        height: 1.3,
                        color: context.textSubColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 10,
                          color: context.textSubColor,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            a.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sub,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule_rounded,
                          size: 10,
                          color: context.textSubColor,
                        ),
                        const SizedBox(width: 2),
                        Text(a.appliedAgo, style: sub),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _MatchBadge(score: a.matchScore),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final s in a.skills.take(4)) SkillChip(s),
              if (a.skills.length > 4) SkillChip('+${a.skills.length - 4}'),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              StatusPill(label: a.status.label, color: a.status.color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${a.expectedSalary} · ${a.noticePeriod}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: headingColor(context),
                  ),
                ),
              ),
              const Spacer(),
              if (onShortlist != null)
                _IconAction(
                  icon: a.status == ApplicantStatus.shortlisted
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppColors.brandAmber,
                  onTap: onShortlist!,
                ),
              if (onMessage != null)
                _IconAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: context.accentColor,
                  onTap: onMessage!,
                ),
              const SizedBox(width: 2),
              ArrowButton(label: 'View', onTap: onTap, height: 25),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = matchColor(score);
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.18 : 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$score%',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text('match', style: GoogleFonts.inter(fontSize: 7.5, color: color)),
        ],
      ),
    );
  }
}
