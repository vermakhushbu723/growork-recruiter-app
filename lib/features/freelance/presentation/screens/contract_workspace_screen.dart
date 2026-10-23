import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../chat/presentation/screens/call_screen.dart';
import '../../data/project_models.dart';
import '../../providers/client_projects_provider.dart';

/// Client side of a contract: fund milestones into escrow, review submitted
/// work, release payment or ask for changes, and end the contract.
class ContractWorkspaceScreen extends ConsumerWidget {
  const ContractWorkspaceScreen({super.key, required this.contractId});

  final String contractId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(clientProjectsProvider).contract(contractId);
    if (c == null) {
      if (!ref.watch(clientProjectsProvider).loaded) return const LoadingView();
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Contract not found',
        ),
      );
    }
    final isActive = c.status == ContractStatus.active;
    final white85 = Colors.white.withValues(alpha: 0.85);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract'),
        actions: [
          IconButton(
            tooltip: 'Call ${c.freelancer}',
            icon: Icon(Icons.call_outlined, color: context.accentColor),
            onPressed: () => context.push(
              RoutePaths.call,
              extra: CallArgs(name: c.freelancer),
            ),
          ),
          IconButton(
            tooltip: 'Message ${c.freelancer}',
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: context.accentColor,
            ),
            onPressed: () => context.push(
              RoutePaths.chatRoom,
              extra: ChatTarget(
                userId: c.freelancerId,
                name: c.freelancer,
                context: c.title,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(12),
            onTap: () =>
                context.push(RoutePaths.projectDetails, extra: c.projectId),
            child: Row(
              children: [
                UserAvatar(name: c.freelancer, size: 42),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: headingColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Freelancer: ${c.freelancer} · Started ${c.startedOn}',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: context.textSubColor,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label: isActive ? 'Active' : 'Completed',
                  color: isActive ? AppColors.tintBlue : AppColors.tintGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paid to freelancer',
                  style: TextStyle(color: white85, fontSize: 10.5),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRupees(c.released),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: c.progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: 'Contract value',
                        value: formatRupees(c.total),
                      ),
                    ),
                    Expanded(
                      child: _HeroStat(
                        label: 'In escrow',
                        value: formatRupees(c.inEscrow),
                      ),
                    ),
                    Expanded(
                      child: _HeroStat(
                        label: 'Progress',
                        value: '${(c.progress * 100).round()}%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionLabel(
            'Milestones',
            trailing: isActive
                ? TextButton.icon(
                    onPressed: () => _addMilestone(context, ref, c),
                    icon: const Icon(Icons.add_rounded, size: 15),
                    label: const Text('Add'),
                  )
                : null,
          ),
          Text(
            'Fund a milestone to let work begin. Money stays in escrow until you approve the delivery.',
            style: TextStyle(fontSize: 9.5, color: context.textSubColor),
          ),
          const SizedBox(height: 9),
          for (var i = 0; i < c.milestones.length; i++)
            _MilestoneCard(
              index: i,
              milestone: c.milestones[i],
              active: isActive,
              onFund: () => _fund(context, ref, c, i),
              onRelease: () => _release(context, ref, c, i),
              onRevision: () => _revision(context, ref, c, i),
              onMessage: () => context.push(
                RoutePaths.chatRoom,
                extra: ChatTarget(
                  userId: c.freelancerId,
                  name: c.freelancer,
                  context: c.title,
                ),
              ),
            ),
          if (!isActive && c.review != null) ...[
            const SectionLabel('Your review'),
            SoftCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var s = 1; s <= 5; s++)
                        Icon(
                          s <= (c.rating ?? 0)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 16,
                          color: AppColors.brandAmber,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.review!,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.45,
                      color: context.textSubColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: isActive
          ? BottomActionBar(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push(RoutePaths.endContract, extra: c.id),
                icon: const Icon(Icons.flag_outlined, size: 15),
                label: const Text('End Contract & Leave Review'),
              ),
            )
          : null,
    );
  }

  Future<void> _fund(
    BuildContext context,
    WidgetRef ref,
    ContractModel c,
    int i,
  ) async {
    final m = c.milestones[i];
    final total = (m.amount * 1.03).round();
    final ok = await confirmDialog(
      context,
      title: 'Fund milestone ${i + 1}?',
      message:
          '${formatRupees(total)} (incl. 3% fee) moves from your wallet into escrow. ${c.freelancer} can then start "${m.title}".',
      confirmLabel: 'Fund ${formatRupees(total)}',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(clientProjectsProvider.notifier).fundMilestone(c.id, i);
      if (context.mounted) {
        context.showSnackBar('Milestone funded · ${c.freelancer} notified');
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      context.showSnackBar(e.message, isError: true);
      if (e.status == 402) context.push(RoutePaths.addMoney);
    }
  }

  Future<void> _release(
    BuildContext context,
    WidgetRef ref,
    ContractModel c,
    int i,
  ) async {
    final m = c.milestones[i];
    final ok = await confirmDialog(
      context,
      title: 'Approve & release payment?',
      message:
          '${formatRupees(m.amount)} will be paid to ${c.freelancer} for "${m.title}". This cannot be undone.',
      confirmLabel: 'Release ${formatRupees(m.amount)}',
    );
    if (!ok || !context.mounted) return;
    await context.runApi(
      () => ref.read(clientProjectsProvider.notifier).releaseMilestone(c.id, i),
      success: 'Payment released to ${c.freelancer}',
    );
  }

  Future<void> _revision(
    BuildContext context,
    WidgetRef ref,
    ContractModel c,
    int i,
  ) async {
    final controller = TextEditingController();
    final note = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) => SheetBody(
        title: 'Request changes',
        subtitle: c.milestones[i].title,
        children: [
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            autofocus: true,
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(
              hintText:
                  'What should be changed? Be specific so it is fixed in one go.',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.of(sheetContext).pop(text);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || !context.mounted) return;
    await context.runApi(
      () => ref
          .read(clientProjectsProvider.notifier)
          .requestRevision(c.id, i, note),
      success: 'Revision requested · money stays in escrow',
    );
  }

  Future<void> _addMilestone(
    BuildContext context,
    WidgetRef ref,
    ContractModel c,
  ) async {
    final title = TextEditingController();
    final amount = TextEditingController();
    final added = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) => SheetBody(
        title: 'Add milestone',
        subtitle: 'The freelancer will be asked to accept it',
        children: [
          LabeledField(
            label: 'Title',
            controller: title,
            hint: 'e.g. Extra screens',
          ),
          const SizedBox(height: 10),
          LabeledField(
            label: 'Amount (₹)',
            controller: amount,
            keyboardType: TextInputType.number,
            icon: Icons.currency_rupee_rounded,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (title.text.trim().isEmpty ||
                  (int.tryParse(amount.text) ?? 0) < 100) {
                return;
              }
              Navigator.of(sheetContext).pop(true);
            },
            child: const Text('Add Milestone'),
          ),
        ],
      ),
    );
    if (added == true && context.mounted) {
      final milestone = Milestone(
        title: title.text.trim(),
        amount: int.parse(amount.text),
        dueIn: 'Due in 14 days',
      );
      await context.runApi(
        () => ref
            .read(clientProjectsProvider.notifier)
            .addMilestone(c.id, milestone),
        success: 'Milestone added',
      );
    }
    title.dispose();
    amount.dispose();
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 8.5,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.index,
    required this.milestone,
    required this.active,
    required this.onFund,
    required this.onRelease,
    required this.onRevision,
    required this.onMessage,
  });

  final int index;
  final Milestone milestone;
  final bool active;
  final VoidCallback onFund;
  final VoidCallback onRelease;
  final VoidCallback onRevision;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    final paid = m.status == MilestoneStatus.released;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: paid
                      ? AppColors.success
                      : context.tagBgColor,
                  child: paid
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: context.accentColor,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    m.title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: headingColor(context),
                    ),
                  ),
                ),
                Text(
                  formatRupees(m.amount),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StatusPill(label: m.status.label, color: m.status.color),
                const SizedBox(width: 8),
                Text(
                  m.dueIn,
                  style: TextStyle(fontSize: 9, color: context.textSubColor),
                ),
              ],
            ),
            if (m.note != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.bgColor,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.status == MilestoneStatus.revision
                          ? 'Your change request'
                          : 'Freelancer’s delivery note',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: headingColor(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.note!,
                      style: TextStyle(
                        fontSize: 9.5,
                        height: 1.4,
                        color: context.textSubColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (active) ..._actions(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    switch (milestone.status) {
      case MilestoneStatus.notFunded:
        return [
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onFund,
              icon: const Icon(Icons.lock_outline_rounded, size: 15),
              label: const Text('Fund Milestone'),
            ),
          ),
        ];
      case MilestoneStatus.submitted:
        return [
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRevision,
                  child: const Text('Request Changes'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRelease,
                  child: const Text('Approve & Pay'),
                ),
              ),
            ],
          ),
        ];
      case MilestoneStatus.funded:
      case MilestoneStatus.revision:
        return [
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: 12,
                color: context.textSubColor,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Freelancer is working on this milestone',
                  style: TextStyle(fontSize: 9, color: context.textSubColor),
                ),
              ),
              TextButton(onPressed: onMessage, child: const Text('Message')),
            ],
          ),
        ];
      case MilestoneStatus.released:
        return const [];
    }
  }
}
