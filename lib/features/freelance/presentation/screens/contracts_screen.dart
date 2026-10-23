import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/project_models.dart';
import '../../providers/client_projects_provider.dart';

/// Every freelance contract the client has, active and finished.
class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contracts = ref.watch(clientProjectsProvider).contracts;
    final active = contracts
        .where((c) => c.status == ContractStatus.active)
        .toList();
    final completed = contracts
        .where((c) => c.status == ContractStatus.completed)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contracts'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Active (${active.length})'),
              Tab(text: 'Completed (${completed.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ContractList(
              contracts: active,
              emptyTitle: 'No active contracts',
              emptyMessage:
                  'Hire a freelancer from your project proposals to start one.',
            ),
            _ContractList(
              contracts: completed,
              emptyTitle: 'No completed contracts yet',
              emptyMessage: 'Finished contracts and reviews appear here.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractList extends StatelessWidget {
  const _ContractList({
    required this.contracts,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<ContractModel> contracts;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (contracts.isEmpty) {
      return EmptyState(
        icon: Icons.handshake_outlined,
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: 'My Projects',
        onAction: () => context.go(RoutePaths.projects),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 20),
      itemCount: contracts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _ContractCard(contract: contracts[i]),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.contract});

  final ContractModel contract;

  @override
  Widget build(BuildContext context) {
    final c = contract;
    final sub = context.textSubColor;
    final next = c.milestones
        .where((m) => m.status != MilestoneStatus.released)
        .firstOrNull;
    return SoftCard(
      onTap: () => context.push(RoutePaths.contract, extra: c.id),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: c.freelancer, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: headingColor(context),
                      ),
                    ),
                    Text(
                      '${c.freelancer} · Started ${c.startedOn}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: sub),
                    ),
                  ],
                ),
              ),
              if (c.awaitingReview && c.status == ContractStatus.active)
                const StatusPill(label: 'Review', color: AppColors.tintOrange)
              else if (c.status == ContractStatus.completed && c.rating != null)
                TintTag(
                  '${c.rating!.toStringAsFixed(1)} ★',
                  color: AppColors.brandAmber,
                  height: 17,
                ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: c.progress,
              minHeight: 7,
              backgroundColor: context.tagBgColor,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '${formatRupees(c.released)} of ${formatRupees(c.total)} paid',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              if (c.inEscrow > 0)
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 11, color: sub),
                    const SizedBox(width: 3),
                    Text(
                      '${formatRupees(c.inEscrow)} in escrow',
                      style: TextStyle(fontSize: 9, color: sub),
                    ),
                  ],
                ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                StatusPill(label: next.status.label, color: next.status.color),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Next: ${next.title} · ${next.dueIn}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: sub),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
