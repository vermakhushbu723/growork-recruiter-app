import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../chat/presentation/screens/call_screen.dart';
import '../../data/project_models.dart';
import '../../providers/client_projects_provider.dart';

/// Opening a proposal tells the freelancer it was viewed.
class ProposalDetailsScreen extends ConsumerStatefulWidget {
  const ProposalDetailsScreen({super.key, required this.proposalId});

  final String proposalId;

  @override
  ConsumerState<ProposalDetailsScreen> createState() =>
      _ProposalDetailsScreenState();
}

class _ProposalDetailsScreenState extends ConsumerState<ProposalDetailsScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(clientProjectsProvider.notifier).markViewed(widget.proposalId);
  }

  @override
  Widget build(BuildContext context) =>
      _ProposalDetailsView(proposalId: widget.proposalId);
}

class _ProposalDetailsView extends ConsumerWidget {
  const _ProposalDetailsView({required this.proposalId});

  final String proposalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProjectsProvider);
    final p = client.proposal(proposalId);
    if (p == null) {
      if (!client.loaded) return const LoadingView();
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Proposal not found',
        ),
      );
    }
    final project = client.project(p.projectId);
    final contract = client.contractForProject(p.projectId);
    final sub = context.textSubColor;
    final notifier = ref.read(clientProjectsProvider.notifier);
    final projectTaken =
        project?.hiredFreelancer != null && p.status != ProposalStatus.hired;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposal'),
        actions: [
          IconButton(
            tooltip: 'Call',
            icon: Icon(Icons.call_outlined, color: context.accentColor),
            onPressed: () => context.push(
              RoutePaths.call,
              extra: CallArgs(name: p.freelancer),
            ),
          ),
          IconButton(
            tooltip: 'Message',
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: context.accentColor,
            ),
            onPressed: () => context.push(
              RoutePaths.chatRoom,
              extra: ChatTarget(userId: p.freelancerId, name: p.freelancer),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(13),
            child: Column(
              children: [
                UserAvatar(name: p.freelancer, size: 62),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        p.freelancer,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: headingColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: AppColors.tintBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.headline} · ${p.location}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: sub),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusPill(label: p.status.label, color: p.status.color),
                    if (p.isTopRated)
                      const TintTag(
                        'Top Rated',
                        color: AppColors.tintPurple,
                        icon: Icons.workspace_premium_rounded,
                        height: 17,
                      ),
                    TintTag(
                      '${p.rating} ★',
                      color: AppColors.brandAmber,
                      height: 17,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => context.push(RoutePaths.talentSearch),
                  icon: const Icon(Icons.person_outline_rounded, size: 15),
                  label: const Text('View full profile & portfolio'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 3.1,
            children: [
              StatBox(
                label: p.pricing == PricingType.fixed
                    ? 'Bid amount'
                    : 'Hourly rate',
                value: p.bidLabel,
                icon: Icons.payments_outlined,
                color: AppColors.tintGreen,
              ),
              StatBox(
                label: 'Delivery',
                value: '${p.deliveryDays} days',
                icon: Icons.timer_outlined,
                color: AppColors.tintOrange,
              ),
              StatBox(
                label: 'Jobs completed',
                value: '${p.jobsDone}',
                icon: Icons.task_alt_rounded,
                color: AppColors.tintBlue,
              ),
              StatBox(
                label: 'Job success',
                value: '${p.successRate}%',
                icon: Icons.trending_up_rounded,
                color: AppColors.tintPurple,
              ),
            ],
          ),
          if (project != null) ...[
            const SectionLabel('For your project'),
            MenuTile(
              icon: projectCategoryIcon(project.category),
              color: projectCategoryColor(project.category),
              title: project.title,
              subtitle:
                  'Budget ${project.budgetLabel} · Sent ${p.submittedAgo}',
              onTap: () =>
                  context.push(RoutePaths.projectDetails, extra: project.id),
            ),
          ],
          const SectionLabel('Cover letter'),
          SoftCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              p.coverLetter,
              style: TextStyle(fontSize: 10.5, height: 1.5, color: sub),
            ),
          ),
          const SectionLabel('Skills'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in p.skills)
                TintTag(
                  s,
                  color: project?.skills.contains(s) == true
                      ? AppColors.tintGreen
                      : AppColors.tintBlue,
                  icon: project?.skills.contains(s) == true
                      ? Icons.check_rounded
                      : null,
                  height: 20,
                  fontSize: 9,
                ),
            ],
          ),
          const SectionLabel('Cost breakdown'),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                InfoRow(label: 'Freelancer bid', value: p.bidLabel),
                InfoRow(
                  label: 'Marketplace fee (3%)',
                  value: formatRupees((p.amount * 0.03).round()),
                ),
                const Divider(height: 14),
                InfoRow(
                  label: 'You pay',
                  value:
                      '${formatRupees((p.amount * 1.03).round())}${p.pricing == PricingType.hourly ? ' /hr' : ''}',
                  valueColor: context.accentColor,
                ),
              ],
            ),
          ),
          if (projectTaken) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.tintOrange.withValues(
                  alpha: context.isDark ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'You already hired ${project!.hiredFreelancer} for this project.',
                style: TextStyle(fontSize: 9.5, color: headingColor(context)),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: p.status == ProposalStatus.hired && contract != null
            ? ElevatedButton.icon(
                onPressed: () =>
                    context.push(RoutePaths.contract, extra: contract.id),
                icon: const Icon(Icons.handshake_outlined, size: 15),
                label: const Text('Open Contract'),
              )
            : p.status == ProposalStatus.declined
            ? OutlinedButton.icon(
                onPressed: () => context.runApi(
                  () =>
                      notifier.setProposalStatus(p.id, ProposalStatus.received),
                  success: 'Proposal restored',
                ),
                icon: const Icon(Icons.undo_rounded, size: 15),
                label: const Text('Reconsider Proposal'),
              )
            : Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 40),
                        foregroundColor: AppColors.error,
                        side: const BorderSide(
                          color: AppColors.error,
                          width: 1.2,
                        ),
                      ),
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'Decline proposal?',
                          message:
                              '${p.freelancer} will be told you went with someone else.',
                          confirmLabel: 'Decline',
                          destructive: true,
                        );
                        if (!ok || !context.mounted) return;
                        await context.runApi(
                          () => notifier.setProposalStatus(
                            p.id,
                            ProposalStatus.declined,
                          ),
                          success: 'Proposal declined',
                        );
                      },
                      child: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 40),
                      ),
                      onPressed: () {
                        final on = p.status != ProposalStatus.shortlisted;
                        context.runApi(
                          () => notifier.setProposalStatus(
                            p.id,
                            on
                                ? ProposalStatus.shortlisted
                                : ProposalStatus.received,
                          ),
                          success: on
                              ? 'Shortlisted'
                              : 'Removed from shortlist',
                        );
                      },
                      child: Icon(
                        p.status == ProposalStatus.shortlisted
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: projectTaken
                          ? null
                          : () => context.push(
                              RoutePaths.hireFreelancer,
                              extra: p.id,
                            ),
                      icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                      label: Text('Hire ${p.freelancer.split(' ').first}'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
