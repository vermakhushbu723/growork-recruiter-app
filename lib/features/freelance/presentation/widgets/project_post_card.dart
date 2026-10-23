import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/project_models.dart';

/// A freelance project the client posted, with proposal numbers.
class ProjectPostCard extends StatelessWidget {
  const ProjectPostCard({
    super.key,
    required this.project,
    required this.proposals,
    required this.newProposals,
    required this.onTap,
    this.onProposals,
  });

  final ProjectPost project;
  final int proposals;
  final int newProposals;
  final VoidCallback onTap;
  final VoidCallback? onProposals;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final sub = GoogleFonts.inter(fontSize: 9, color: context.textSubColor);
    final extraSkills = p.skills.length - 4;
    final hired = p.hiredFreelancer;

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBubble(
                icon: projectCategoryIcon(p.category),
                color: projectCategoryColor(p.category),
                size: 43,
                iconSize: 20,
                circle: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: TintTag(
                            p.category,
                            color: projectCategoryColor(p.category),
                          ),
                        ),
                        const SizedBox(width: 5),
                        StatusPill(
                          label: p.status.label,
                          color: p.status.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: headingColor(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 10,
                              color: context.textSubColor,
                            ),
                            const SizedBox(width: 3),
                            Text('$proposals proposals', style: sub),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 9,
                          color: context.borderColor,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 10,
                              color: context.textSubColor,
                            ),
                            const SizedBox(width: 3),
                            Text('${p.views} views', style: sub),
                          ],
                        ),
                        if (newProposals > 0)
                          TintTag(
                            '$newProposals new',
                            color: AppColors.tintGreen,
                            height: 15,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 6,
            children: [
              for (final s in p.skills.take(4)) SkillChip(s),
              if (extraSkills > 0) SkillChip('+$extraSkills'),
            ],
          ),
          if (hired != null) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                UserAvatar(name: hired, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Hired: $hired',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: headingColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        p.budgetLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: context.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${p.pricing.label} · ${p.duration} · ${p.postedAgo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sub,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ArrowButton(
                label: hired != null ? 'Details' : 'Proposals',
                onTap: onProposals ?? onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
