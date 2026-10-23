import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/job_post_model.dart';

Color workModeColor(String mode) => switch (mode) {
  'Remote' => AppColors.tintGreen,
  'Hybrid' => AppColors.tintTeal,
  _ => AppColors.tintRed,
};

Color levelColor(String level) => switch (level) {
  'Junior Level' => AppColors.tintOrange,
  'Fresher' => AppColors.tintBlue,
  'Senior Level' => AppColors.tintTeal,
  _ => AppColors.tintPurple,
};

Color jobTypeColor(String type) => switch (type) {
  'Internship' => AppColors.tintOrange,
  'Contract' => AppColors.tintPurple,
  'Part-time' => AppColors.tintTeal,
  _ => AppColors.tintBlue,
};

/// A job the recruiter posted, with its applicant numbers.
class JobPostCard extends StatelessWidget {
  const JobPostCard({
    super.key,
    required this.job,
    required this.company,
    required this.applicants,
    required this.newApplicants,
    required this.onTap,
    this.onApplicants,
    this.compact = false,
  });

  final JobPost job;
  final String company;
  final int applicants;
  final int newApplicants;
  final VoidCallback onTap;
  final VoidCallback? onApplicants;

  /// Small row used on the dashboard.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      radius: compact ? 8 : 9,
      padding: compact
          ? const EdgeInsets.fromLTRB(11, 8, 8, 8)
          : const EdgeInsets.fromLTRB(10, 9, 9, 8),
      child: compact ? _compact(context) : _full(context),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 9.5, color: context.textSubColor),
      const SizedBox(width: 3),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 8, color: context.textSubColor),
        ),
      ),
    ],
  );

  Widget _compact(BuildContext context) {
    return Row(
      children: [
        CompanyLogo(name: company, size: 40),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: headingColor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${job.type} · ${job.workMode} · ${job.postedAgo}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  color: context.textSubColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  TintTag(
                    '$applicants applicants',
                    color: AppColors.tintBlue,
                    icon: Icons.people_alt_rounded,
                    height: 16,
                  ),
                  if (newApplicants > 0) ...[
                    const SizedBox(width: 5),
                    TintTag(
                      '$newApplicants new',
                      color: AppColors.tintGreen,
                      height: 16,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusPill(label: job.status.label, color: job.status.color),
            const SizedBox(height: 6),
            Text(
              job.shortSalary,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: context.accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _full(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: CompanyLogo(name: company, size: 41),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          job.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: headingColor(context),
                          ),
                        ),
                      ),
                      if (job.isUrgent) ...[
                        const SizedBox(width: 6),
                        const TintTag(
                          'Urgent',
                          color: AppColors.urgentTxt,
                          icon: Icons.local_fire_department_rounded,
                          height: 16,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${job.category} · ${job.openings} opening${job.openings == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      height: 1.25,
                      color: context.textSubColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      TintTag(
                        job.type,
                        color: jobTypeColor(job.type),
                        height: 16,
                      ),
                      const SizedBox(width: 6),
                      TintTag(
                        job.workMode,
                        color: workModeColor(job.workMode),
                        height: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: TintTag(
                          job.level,
                          color: levelColor(job.level),
                          height: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: _meta(
                          context,
                          Icons.location_on_outlined,
                          job.location,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _meta(
                        context,
                        Icons.work_outline_rounded,
                        job.experience,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _meta(
                          context,
                          Icons.schedule_rounded,
                          job.postedAgo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            StatusPill(label: job.status.label, color: job.status.color),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Stat(
              icon: Icons.people_alt_outlined,
              value: '$applicants',
              label: 'Applicants',
              color: AppColors.tintBlue,
            ),
            const SizedBox(width: 6),
            _Stat(
              icon: Icons.fiber_new_outlined,
              value: '$newApplicants',
              label: 'New',
              color: AppColors.tintGreen,
            ),
            const SizedBox(width: 6),
            _Stat(
              icon: Icons.visibility_outlined,
              value: '${job.views}',
              label: 'Views',
              color: AppColors.tintPurple,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  job.salaryLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: context.accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ArrowButton(
              label: 'Applicants',
              onTap: onApplicants ?? onTap,
              height: 27,
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: context.isDark ? 0.16 : 0.07),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: headingColor(context),
              ),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  color: context.textSubColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
