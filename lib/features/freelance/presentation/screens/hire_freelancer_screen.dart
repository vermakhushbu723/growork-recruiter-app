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
import '../../../../core/widgets/success_view.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../wallet/providers/wallet_provider.dart';
import '../../data/project_models.dart';
import '../../providers/client_projects_provider.dart';

class _MilestoneDraft {
  _MilestoneDraft(String title, int amount, this.days)
    : title = TextEditingController(text: title),
      amount = TextEditingController(text: '$amount');

  final TextEditingController title;
  final TextEditingController amount;
  int days;

  void dispose() {
    title.dispose();
    amount.dispose();
  }
}

/// Turns an accepted proposal into a contract: split the work into
/// milestones and fund the first one into escrow.
class HireFreelancerScreen extends ConsumerStatefulWidget {
  const HireFreelancerScreen({super.key, required this.proposalId});

  final String proposalId;

  @override
  ConsumerState<HireFreelancerScreen> createState() =>
      _HireFreelancerScreenState();
}

class _HireFreelancerScreenState extends ConsumerState<HireFreelancerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Proposal? _proposal = ref
      .read(clientProjectsProvider)
      .proposal(widget.proposalId);
  late final List<_MilestoneDraft> _milestones = _initialMilestones();
  bool _agree = true;
  bool _busy = false;
  ContractModel? _contract;

  List<_MilestoneDraft> _initialMilestones() {
    final p = _proposal;
    if (p == null) return [];
    if (p.pricing == PricingType.hourly) {
      // A weekly cap of 20 hours, funded week by week.
      return [
        _MilestoneDraft('Week 1 (up to 20 hrs)', p.amount * 20, 7),
        _MilestoneDraft('Week 2 (up to 20 hrs)', p.amount * 20, 14),
      ];
    }
    final half = (p.amount / 2).round();
    return [
      _MilestoneDraft('First delivery', half, (p.deliveryDays / 2).ceil()),
      _MilestoneDraft(
        'Final delivery & handover',
        p.amount - half,
        p.deliveryDays,
      ),
    ];
  }

  @override
  void dispose() {
    for (final m in _milestones) {
      m.dispose();
    }
    super.dispose();
  }

  int _amountOf(_MilestoneDraft m) => int.tryParse(m.amount.text) ?? 0;
  int get _total => _milestones.fold(0, (s, m) => s + _amountOf(m));
  int get _firstFunding =>
      _milestones.isEmpty ? 0 : (_amountOf(_milestones.first) * 1.03).round();

  Future<void> _hire() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      context.showSnackBar('Please accept the contract terms', isError: true);
      return;
    }
    final p = _proposal!;
    setState(() => _busy = true);
    try {
      final contract = await ref
          .read(clientProjectsProvider.notifier)
          .hire(p.id, [
            for (final m in _milestones)
              Milestone(
                title: m.title.text.trim(),
                amount: _amountOf(m),
                dueIn: 'Due in ${m.days} days',
              ),
          ]);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _contract = contract;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.status == 402) {
        final add = await confirmDialog(
          context,
          title: 'Not enough balance',
          message:
              'You need ${formatRupees(_firstFunding)} to fund the first milestone. Add money to your wallet to continue.',
          confirmLabel: 'Add Money',
        );
        if (add && mounted) context.push(RoutePaths.addMoney);
      } else {
        context.showSnackBar(e.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _proposal;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Proposal not found',
        ),
      );
    }
    final contract = _contract;
    if (contract != null) {
      return SuccessView(
        icon: Icons.handshake_rounded,
        title: '${p.freelancer.split(' ').first} is hired!',
        message:
            'The contract has started and ${formatRupees(_amountOf(_milestones.first))} is safely held in escrow for the first milestone.',
        primaryLabel: 'Open Contract',
        onPrimary: () =>
            context.pushReplacement(RoutePaths.contract, extra: contract.id),
        secondaryLabel: 'Message ${p.freelancer.split(' ').first}',
        onSecondary: () => context.pushReplacement(
          RoutePaths.chatRoom,
          extra: ChatTarget(userId: p.freelancerId, name: p.freelancer),
        ),
      );
    }

    final project = ref.watch(clientProjectsProvider).project(p.projectId);
    final balance = ref.watch(walletProvider).balance;
    final enough = balance >= _firstFunding;

    return Scaffold(
      appBar: AppBar(title: const Text('Hire Freelancer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
          children: [
            SoftCard(
              padding: const EdgeInsets.all(11),
              child: Row(
                children: [
                  UserAvatar(name: p.freelancer, size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.freelancer,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: headingColor(context),
                          ),
                        ),
                        Text(
                          project?.title ?? p.headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: context.textSubColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        p.bidLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: context.accentColor,
                        ),
                      ),
                      Text(
                        '${p.deliveryDays} days',
                        style: TextStyle(
                          fontSize: 9,
                          color: context.textSubColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SectionLabel(
              p.pricing == PricingType.fixed ? 'Milestones' : 'Weekly limits',
              trailing: TextButton.icon(
                onPressed: () => setState(
                  () => _milestones.add(
                    _MilestoneDraft(
                      'Milestone ${_milestones.length + 1}',
                      0,
                      (_milestones.lastOrNull?.days ?? 0) + 7,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('Add'),
              ),
            ),
            Text(
              'Split the work into parts. You fund one milestone at a time — the freelancer is paid only when you approve it.',
              style: TextStyle(fontSize: 9.5, color: context.textSubColor),
            ),
            const SizedBox(height: 9),
            for (final (i, m) in _milestones.indexed) ...[
              SoftCard(
                padding: const EdgeInsets.fromLTRB(11, 10, 6, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: i == 0
                            ? AppColors.tintGreen
                            : context.tagBgColor,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: i == 0 ? Colors.white : context.accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: m.title,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textMainColor,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'What will be delivered?',
                            ),
                            validator: (v) =>
                                (v ?? '').trim().isEmpty ? 'Add a title' : null,
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: m.amount,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.textMainColor,
                                  ),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.currency_rupee_rounded,
                                      size: 15,
                                    ),
                                    hintText: 'Amount',
                                  ),
                                  validator: (v) =>
                                      (int.tryParse(v ?? '') ?? 0) < 100
                                      ? 'Min ₹100'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 7),
                              PopupMenuButton<int>(
                                initialValue: m.days,
                                onSelected: (d) => setState(() => m.days = d),
                                itemBuilder: (_) => [
                                  for (final d in const [
                                    3,
                                    5,
                                    7,
                                    10,
                                    14,
                                    21,
                                    30,
                                    45,
                                  ])
                                    PopupMenuItem(
                                      value: d,
                                      child: Text('Due in $d days'),
                                    ),
                                ],
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.tagBgColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.event_outlined,
                                        size: 13,
                                        color: context.accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${m.days} days',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: context.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _milestones.length > 1
                          ? () => setState(
                              () => _milestones.removeAt(i).dispose(),
                            )
                          : null,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
            const SectionLabel('Payment summary'),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  InfoRow(label: 'Contract total', value: formatRupees(_total)),
                  InfoRow(
                    label: 'Fund now (M1 + 3% fee)',
                    value: formatRupees(_firstFunding),
                    valueColor: context.accentColor,
                  ),
                  InfoRow(
                    label: 'Wallet balance',
                    value: formatRupees(balance),
                    valueColor: enough ? AppColors.tintGreen : AppColors.error,
                  ),
                ],
              ),
            ),
            if (!enough) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => context.push(RoutePaths.addMoney),
                icon: const Icon(Icons.add_card_rounded, size: 15),
                label: const Text('Add money to wallet'),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                ),
                Expanded(
                  child: Text(
                    'I agree to the Subkamyaab contract terms and escrow policy',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.textSubColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: 'Hire & Fund ${formatRupees(_firstFunding)}',
          icon: Icons.lock_rounded,
          loading: _busy,
          onPressed: _hire,
        ),
      ),
    );
  }
}
