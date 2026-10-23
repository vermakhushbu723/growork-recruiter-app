import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/banners.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/project_models.dart';
import '../../providers/client_projects_provider.dart';
import '../widgets/proposal_card.dart';

class ProjectPostDetailsScreen extends ConsumerWidget {
  const ProjectPostDetailsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProjectsProvider);
    final p = client.project(projectId);
    if (p == null) {
      if (!client.loaded) return const LoadingView();
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Project not found',
          message: 'It may have been deleted.',
        ),
      );
    }
    final proposals = client.proposalsFor(p.id)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final contract = client.contractForProject(p.id);
    final sub = context.textSubColor;
    int count(ProposalStatus s) => proposals.where((x) => x.status == s).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          if (p.status == ProjectStatus.open || p.status == ProjectStatus.draft)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push(RoutePaths.postProject, extra: p.id),
            ),
          IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showActions(context, ref, p),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBubble(
                      icon: projectCategoryIcon(p.category),
                      color: projectCategoryColor(p.category),
                      size: 46,
                      iconSize: 22,
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
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              color: headingColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Posted ${p.postedAgo} · ${p.level} level · ${p.views} views',
                  style: TextStyle(fontSize: 9, color: sub),
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
                label: p.pricing.label,
                value: p.budgetLabel,
                icon: Icons.payments_outlined,
                color: AppColors.tintGreen,
              ),
              StatBox(
                label: 'Duration',
                value: p.duration,
                icon: Icons.timer_outlined,
                color: AppColors.tintOrange,
              ),
              StatBox(
                label: 'Proposals',
                value: '${proposals.length}',
                icon: Icons.description_outlined,
                color: AppColors.tintBlue,
              ),
              StatBox(
                label: 'Shortlisted',
                value: '${count(ProposalStatus.shortlisted)}',
                icon: Icons.star_border_rounded,
                color: AppColors.brandAmber,
              ),
            ],
          ),
          if (contract != null) ...[
            const SectionLabel('Contract'),
            SoftCard(
              onTap: () =>
                  context.push(RoutePaths.contract, extra: contract.id),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(name: contract.freelancer, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contract.freelancer,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: headingColor(context),
                              ),
                            ),
                            Text(
                              'Started ${contract.startedOn}',
                              style: TextStyle(fontSize: 9, color: sub),
                            ),
                          ],
                        ),
                      ),
                      StatusPill(
                        label: contract.status == ContractStatus.active
                            ? 'Active'
                            : 'Completed',
                        color: contract.status == ContractStatus.active
                            ? AppColors.tintBlue
                            : AppColors.tintGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: contract.progress,
                      minHeight: 7,
                      backgroundColor: context.tagBgColor,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${formatRupees(contract.released)} of ${formatRupees(contract.total)} paid · ${formatRupees(contract.inEscrow)} in escrow',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (proposals.isNotEmpty) ...[
            const SectionLabel('Proposals'),
            PipelineStrip(
              items: [
                for (final s in ProposalStatus.values)
                  (
                    label: s.label,
                    count: count(s),
                    color: s.color,
                    onTap: () =>
                        context.push(RoutePaths.proposals, extra: p.id),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final prop in proposals.take(2)) ...[
              ProposalCard(
                proposal: prop,
                onTap: () =>
                    context.push(RoutePaths.proposalDetails, extra: prop.id),
              ),
              const SizedBox(height: 6),
            ],
            if (proposals.length > 2)
              TextButton(
                onPressed: () =>
                    context.push(RoutePaths.proposals, extra: p.id),
                child: Text('See all ${proposals.length} proposals'),
              ),
          ],
          const SectionLabel('Project description'),
          SoftCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              p.description,
              style: TextStyle(fontSize: 10.5, height: 1.5, color: sub),
            ),
          ),
          const SectionLabel('Skills required'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in p.skills)
                TintTag(s, color: AppColors.tintBlue, height: 20, fontSize: 9),
            ],
          ),
          if (p.attachments.isNotEmpty) ...[
            const SectionLabel('Attachments'),
            for (final f in p.attachments) ...[
              MenuTile(
                icon: Icons.insert_drive_file_outlined,
                color: AppColors.tintRed,
                title: f,
                subtitle: 'Shared with freelancers',
                onTap: () => context.showSnackBar('Opening $f'),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: switch (p.status) {
          ProjectStatus.draft => ElevatedButton.icon(
            onPressed: () => context.push(RoutePaths.postProject, extra: p.id),
            icon: const Icon(Icons.rocket_launch_rounded, size: 15),
            label: const Text('Finish & Post'),
          ),
          ProjectStatus.open => Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(RoutePaths.talentSearch),
                  icon: const Icon(Icons.person_add_alt_rounded, size: 15),
                  label: const Text('Invite'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push(RoutePaths.proposals, extra: p.id),
                  icon: const Icon(Icons.description_outlined, size: 15),
                  label: Text('Review Proposals (${proposals.length})'),
                ),
              ),
            ],
          ),
          _ when contract != null => ElevatedButton.icon(
            onPressed: () =>
                context.push(RoutePaths.contract, extra: contract.id),
            icon: const Icon(Icons.handshake_outlined, size: 15),
            label: const Text('Open Contract'),
          ),
          _ => OutlinedButton.icon(
            onPressed: () => context.push(RoutePaths.postProject),
            icon: const Icon(Icons.add_rounded, size: 15),
            label: const Text('Post a New Project'),
          ),
        },
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref, ProjectPost p) {
    final notifier = ref.read(clientProjectsProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Manage project',
        subtitle: p.title,
        children: [
          if (p.status == ProjectStatus.open)
            SheetOption(
              icon: Icons.lock_outline_rounded,
              label: 'Close to new proposals',
              onTap: () {
                Navigator.pop(sheetContext);
                context.runApi(
                  () => notifier.setProjectStatus(p.id, ProjectStatus.closed),
                  success: 'Project closed',
                );
              },
            ),
          if (p.status == ProjectStatus.closed)
            SheetOption(
              icon: Icons.lock_open_rounded,
              label: 'Re-open project',
              onTap: () {
                Navigator.pop(sheetContext);
                context.runApi(
                  () => notifier.setProjectStatus(p.id, ProjectStatus.open),
                  success: 'Project is open again',
                );
              },
            ),
          SheetOption(
            icon: Icons.share_outlined,
            label: 'Share project link',
            onTap: () {
              Navigator.pop(sheetContext);
              context.showSnackBar('Project link copied');
            },
          ),
          if (p.status != ProjectStatus.inProgress)
            SheetOption(
              icon: Icons.delete_outline_rounded,
              label: 'Delete project',
              destructive: true,
              onTap: () async {
                Navigator.pop(sheetContext);
                final ok = await confirmDialog(
                  context,
                  title: 'Delete project?',
                  message:
                      '"${p.title}" and all its proposals will be removed permanently.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                final deleted = await context.runApi(
                  () => notifier.deleteProject(p.id),
                  success: 'Project deleted',
                );
                if (deleted && context.mounted) context.pop();
              },
            ),
        ],
      ),
    );
  }
}
