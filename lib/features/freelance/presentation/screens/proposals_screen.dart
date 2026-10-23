import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/project_models.dart';
import '../../providers/client_projects_provider.dart';
import '../widgets/proposal_card.dart';

class ProposalsScreen extends ConsumerStatefulWidget {
  const ProposalsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProposalsScreen> createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends ConsumerState<ProposalsScreen> {
  ProposalStatus? _status;
  String _sort = 'Best rated';

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientProjectsProvider);
    final project = client.project(widget.projectId);
    final all = client.proposalsFor(widget.projectId);
    final list = all
        .where((p) => _status == null || p.status == _status)
        .toList();
    switch (_sort) {
      case 'Lowest bid':
        list.sort((a, b) => a.amount.compareTo(b.amount));
      case 'Fastest delivery':
        list.sort((a, b) => a.deliveryDays.compareTo(b.deliveryDays));
      default:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    final avgBid = all.isEmpty
        ? 0
        : all.fold(0, (s, p) => s + p.amount) ~/ all.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Proposals'),
            Text(
              project?.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: context.textSubColor,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          if (project != null && all.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 2, 13, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: StatBox(
                        label: 'Your budget',
                        value: project.budgetLabel,
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.tintTeal,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: StatBox(
                        label: 'Average bid',
                        value: project.pricing == PricingType.fixed
                            ? formatRupees(avgBid)
                            : '${formatRupees(avgBid)} /hr',
                        icon: Icons.bar_chart_rounded,
                        color: AppColors.tintPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: ChipScroller(
              children: [
                PillChip(
                  label: 'All (${all.length})',
                  selected: _status == null,
                  onTap: () => setState(() => _status = null),
                ),
                for (final s in ProposalStatus.values)
                  PillChip(
                    label:
                        '${s.label} (${all.where((p) => p.status == s).length})',
                    color: s.color,
                    selected: _status == s,
                    onTap: () => setState(() => _status = s),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 10, 6),
              child: SectionTitle(
                '${list.length} proposal${list.length == 1 ? '' : 's'}',
                trailing: SortByButton(
                  value: _sort,
                  onTap: () => _showSortSheet(context),
                ),
              ),
            ),
          ),
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No proposals here yet',
                message: 'Invite freelancers to get proposals faster',
                actionLabel: 'Find Freelancers',
                onAction: () => context.push(RoutePaths.talentSearch),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 20),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = list[i];
                  return ProposalCard(
                    proposal: p,
                    onTap: () =>
                        context.push(RoutePaths.proposalDetails, extra: p.id),
                    onShortlist: p.status == ProposalStatus.hired
                        ? null
                        : () => _toggleShortlist(p),
                    onMessage: () => context.push(
                      RoutePaths.chatRoom,
                      extra: ChatTarget(
                        userId: p.freelancerId,
                        name: p.freelancer,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _toggleShortlist(Proposal p) {
    final notifier = ref.read(clientProjectsProvider.notifier);
    final on = p.status != ProposalStatus.shortlisted;
    context.runApi(
      () => notifier.setProposalStatus(
        p.id,
        on ? ProposalStatus.shortlisted : ProposalStatus.received,
      ),
      success: on
          ? '${p.freelancer} shortlisted'
          : '${p.freelancer} removed from shortlist',
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Sort proposals by',
        children: [
          for (final o in const [
            (Icons.star_border_rounded, 'Best rated'),
            (Icons.payments_outlined, 'Lowest bid'),
            (Icons.bolt_rounded, 'Fastest delivery'),
          ])
            SheetOption(
              icon: o.$1,
              label: o.$2,
              selected: _sort == o.$2,
              onTap: () {
                setState(() => _sort = o.$2);
                Navigator.pop(sheetContext);
              },
            ),
        ],
      ),
    );
  }
}
