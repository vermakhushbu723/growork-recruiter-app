import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/success_view.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/project_models.dart';
import '../../providers/client_projects_provider.dart';

const _tags = [
  'Great communication',
  'Delivered on time',
  'High quality work',
  'Followed instructions',
  'Would hire again',
];

class EndContractScreen extends ConsumerStatefulWidget {
  const EndContractScreen({super.key, required this.contractId});

  final String contractId;

  @override
  ConsumerState<EndContractScreen> createState() => _EndContractScreenState();
}

class _EndContractScreenState extends ConsumerState<EndContractScreen> {
  final _review = TextEditingController();
  final _private = TextEditingController();
  int _rating = 5;
  Set<String> _selected = {'Great communication', 'Would hire again'};
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    _review.dispose();
    _private.dispose();
    super.dispose();
  }

  Future<void> _submit(ContractModel c) async {
    if (_review.text.trim().length < 10) {
      context.showSnackBar(
        'Write a short public review (10+ characters)',
        isError: true,
      );
      return;
    }
    setState(() => _busy = true);
    // The server refunds funded-but-unapproved milestones to the wallet.
    final ok = await context.runApi(
      () => ref
          .read(clientProjectsProvider.notifier)
          .endContract(c.id, _rating.toDouble(), _review.text.trim()),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(clientProjectsProvider).contract(widget.contractId);
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
    if (_done) {
      return SuccessView(
        icon: Icons.emoji_events_rounded,
        color: AppColors.brandAmber,
        title: 'Contract Completed',
        message:
            'Thanks for reviewing ${c.freelancer}! Your feedback helps other clients hire with confidence.',
        primaryLabel: 'Back to Contracts',
        onPrimary: () => context.pushReplacement(RoutePaths.contracts),
        secondaryLabel: 'Post a New Project',
        onSecondary: () => context.pushReplacement(RoutePaths.postProject),
      );
    }
    final unpaid = c.milestones
        .where((m) => m.status != MilestoneStatus.released)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('End Contract')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(13),
            child: Column(
              children: [
                UserAvatar(name: c.freelancer, size: 56),
                const SizedBox(height: 8),
                Text(
                  'How was working with ${c.freelancer.split(' ').first}?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: headingColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: context.textSubColor),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var s = 1; s <= 5; s++)
                      InkResponse(
                        onTap: () => setState(() => _rating = s),
                        radius: 22,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            s <= _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 34,
                            color: AppColors.brandAmber,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  switch (_rating) {
                    5 => 'Excellent',
                    4 => 'Good',
                    3 => 'Okay',
                    2 => 'Poor',
                    _ => 'Very poor',
                  },
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MultiChipGroup(
            label: 'What went well?',
            options: _tags,
            values: _selected,
            onChanged: (v) => setState(() => _selected = v),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Public review',
            hint: 'Shown on the freelancer’s profile',
            controller: _review,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Private feedback to Subkamyaab (optional)',
            hint: 'Only our team sees this',
            controller: _private,
            maxLines: 3,
          ),
          if (unpaid.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.tintOrange.withValues(
                  alpha: context.isDark ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.tintOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${unpaid.length} milestone${unpaid.length == 1 ? ' is' : 's are'} not paid. '
                      '${c.inEscrow > 0 ? '${formatRupees(c.inEscrow)} in escrow will be refunded to your wallet.' : 'Nothing is held in escrow.'}',
                      style: TextStyle(
                        fontSize: 9.5,
                        height: 1.4,
                        color: headingColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: 'Submit Review & End Contract',
          loading: _busy,
          onPressed: () => _submit(c),
        ),
      ),
    );
  }
}
