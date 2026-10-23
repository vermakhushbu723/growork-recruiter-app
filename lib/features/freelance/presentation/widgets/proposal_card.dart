import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/project_models.dart';

/// A freelancer's proposal on one of the client's projects.
class ProposalCard extends StatelessWidget {
  const ProposalCard({
    super.key,
    required this.proposal,
    required this.onTap,
    this.onShortlist,
    this.onMessage,
  });

  final Proposal proposal;
  final VoidCallback onTap;
  final VoidCallback? onShortlist;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final p = proposal;
    final sub = GoogleFonts.inter(fontSize: 9, color: context.textSubColor);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(11, 9, 9, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(name: p.freelancer, size: 40),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.freelancer,
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
                        if (p.isTopRated) ...[
                          const SizedBox(width: 5),
                          const TintTag(
                            'Top Rated',
                            color: AppColors.tintPurple,
                            icon: Icons.workspace_premium_rounded,
                            height: 15,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${p.headline} · ${p.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sub.copyWith(fontSize: 9.5),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: AppColors.brandAmber,
                        ),
                        const SizedBox(width: 3),
                        Text('${p.rating}', style: sub),
                        const SizedBox(width: 8),
                        Text('${p.jobsDone} jobs', style: sub),
                        const SizedBox(width: 8),
                        Text('${p.successRate}% success', style: sub),
                      ],
                    ),
                  ],
                ),
              ),
              StatusPill(label: p.status.label, color: p.status.color),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            p.coverLetter,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              height: 1.4,
              color: context.textSubColor,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.bidLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: context.accentColor,
                    ),
                  ),
                  Text(
                    'Delivery in ${p.deliveryDays} days · ${p.submittedAgo}',
                    style: sub.copyWith(fontSize: 8.5),
                  ),
                ],
              ),
              const Spacer(),
              if (onShortlist != null)
                InkResponse(
                  onTap: onShortlist,
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      p.status == ProposalStatus.shortlisted
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 18,
                      color: AppColors.brandAmber,
                    ),
                  ),
                ),
              if (onMessage != null)
                InkResponse(
                  onTap: onMessage,
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 17,
                      color: context.accentColor,
                    ),
                  ),
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
