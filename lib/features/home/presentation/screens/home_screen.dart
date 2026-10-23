import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/animations/fade_slide_up.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/activity_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../freelance/data/project_models.dart';
import '../../../freelance/providers/client_projects_provider.dart';
import '../../../jobs/data/job_post_model.dart';
import '../../../jobs/presentation/widgets/applicant_card.dart';
import '../../../jobs/presentation/widgets/job_post_card.dart';
import '../../../jobs/providers/recruitment_provider.dart';
import '../../../wallet/providers/wallet_provider.dart';
import '../widgets/hiring_overview_card.dart';
import '../widgets/home_header.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/quick_actions_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final hiring = ref.watch(recruitmentProvider);
    final client = ref.watch(clientProjectsProvider);
    final wallet = ref.watch(walletProvider);
    final company = user?.company.name ?? 'your team';

    final recentApplicants = hiring.applicants
        .where((a) => a.status == ApplicantStatus.applied)
        .take(3)
        .toList();
    final activeJobs = hiring.activeJobs.take(3).toList();
    final openProjects = client.projects
        .where((p) => p.status == ProjectStatus.open)
        .length;
    final newProposals = client.proposals
        .where((p) => p.status == ProposalStatus.received)
        .length;
    final nextInterview = hiring.upcomingInterviews.firstOrNull;

    final attention = <Widget>[
      if (client.awaitingReview > 0)
        _AttentionTile(
          icon: Icons.rate_review_outlined,
          color: AppColors.tintOrange,
          title: 'Work submitted for review',
          subtitle:
              '${client.awaitingReview} milestone${client.awaitingReview == 1 ? '' : 's'} waiting for your approval',
          onTap: () => context.push(RoutePaths.contracts),
        ),
      if (nextInterview != null)
        _AttentionTile(
          icon: Icons.event_available_outlined,
          color: AppColors.tintPurple,
          title: 'Next interview · ${nextInterview.candidateName}',
          subtitle:
              '${DateFormat('EEE, d MMM · h:mm a').format(nextInterview.dateTime)} · ${nextInterview.round}',
          onTap: () => context.push(RoutePaths.interviews),
        ),
      if (newProposals > 0)
        _AttentionTile(
          icon: Icons.description_outlined,
          color: AppColors.tintGreen,
          title: '$newProposals new freelance proposals',
          subtitle: 'Review bids on your open projects',
          onTap: () => context.go(RoutePaths.projects),
        ),
    ];

    var i = 0;
    Widget anim(Widget child) => FadeSlideUp(index: i++, child: child);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.read(recruitmentProvider.notifier).load(),
            ref.read(clientProjectsProvider.notifier).load(),
            ref.read(walletProvider.notifier).load(),
            ref.read(notificationsProvider.notifier).load(),
          ]),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(13, 0, 13, 16),
            children: [
              anim(
                HomeHeader(
                  userName: user?.name ?? 'Recruiter',
                  company: company,
                  unread: ref.watch(notificationsProvider).unread,
                ),
              ),
              const SizedBox(height: 10),
              anim(
                HiringOverviewCard(
                  activeJobs: hiring.activeJobs.length,
                  newApplicants: hiring.newApplicants,
                  openProjects: openProjects,
                  interviews: hiring.upcomingInterviews.length,
                  walletBalance: formatRupees(wallet.balance),
                ),
              ),
              const SizedBox(height: 11),
              anim(
                SearchFilterBar(
                  hint: 'Search candidates, freelancers or skills...',
                  height: 38,
                  insetFilter: true,
                  onSubmitted: (_) => context.push(RoutePaths.talentSearch),
                  onFilter: () => context.push(RoutePaths.talentSearch),
                ),
              ),
              const SizedBox(height: 9),
              anim(const QuickActionsGrid()),
              const SizedBox(height: 9),
              anim(const PromoCarousel()),
              if (attention.isNotEmpty) ...[
                const SizedBox(height: 8),
                anim(const SectionTitle('Needs your attention')),
                const SizedBox(height: 6),
                for (final (j, w) in attention.indexed) ...[
                  if (j > 0) const SizedBox(height: 5),
                  anim(w),
                ],
              ],
              const SizedBox(height: 10),
              anim(
                SectionTitle(
                  'New Applicants',
                  trailing: _SeeAll(
                    onTap: () => context.push(RoutePaths.applicants),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (recentApplicants.isEmpty)
                anim(const _EmptyNote('No new applicants right now'))
              else
                for (final (j, a) in recentApplicants.indexed) ...[
                  if (j > 0) const SizedBox(height: 6),
                  anim(
                    ApplicantCard(
                      applicant: a,
                      jobTitle: hiring.job(a.jobId)?.title,
                      onTap: () => context.push(
                        RoutePaths.applicantProfile,
                        extra: a.id,
                      ),
                    ),
                  ),
                ],
              const SizedBox(height: 10),
              anim(
                SectionTitle(
                  'Your Active Jobs',
                  trailing: _SeeAll(onTap: () => context.go(RoutePaths.jobs)),
                ),
              ),
              const SizedBox(height: 6),
              if (activeJobs.isEmpty)
                anim(
                  const _EmptyNote('No active jobs — post one to start hiring'),
                )
              else
                for (final (j, job) in activeJobs.indexed) ...[
                  if (j > 0) const SizedBox(height: 4),
                  anim(
                    JobPostCard(
                      job: job,
                      company: company,
                      compact: true,
                      applicants: hiring.applicantsFor(job.id).length,
                      newApplicants: hiring.countFor(
                        job.id,
                        ApplicantStatus.applied,
                      ),
                      onTap: () =>
                          context.push(RoutePaths.jobDetails, extra: job.id),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'See all',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: context.accentColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward_rounded,
            size: 12,
            color: context.accentColor,
          ),
        ],
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenuTile(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: context.textSubColor),
      ),
    );
  }
}
