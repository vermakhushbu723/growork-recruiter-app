import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../freelance/data/project_models.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  int _filter = 0; // 0 all, 1 credits, 2 debits

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final txs = wallet.transactions
        .where((t) => _filter == 0 || (_filter == 1) == t.isCredit)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet & Payments'),
        actions: [
          IconButton(
            tooltip: 'Invoices',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () =>
                context.showSnackBar('GST invoices emailed to your company'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Company Wallet Balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupees(wallet.balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _HeroButton(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Withdraw',
                        onTap: () => context.push(RoutePaths.withdraw),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroButton(
                        icon: Icons.add_rounded,
                        label: 'Add Money',
                        solid: true,
                        onTap: () => context.push(RoutePaths.addMoney),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: StatBox(
                  label: 'Held in escrow',
                  value: formatRupees(wallet.escrow),
                  icon: Icons.lock_outline_rounded,
                  color: AppColors.tintOrange,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: StatBox(
                  label: 'Spent this month',
                  value: formatRupees(wallet.spentThisMonth),
                  icon: Icons.trending_down_rounded,
                  color: AppColors.tintRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          MenuTile(
            icon: Icons.workspace_premium_outlined,
            color: AppColors.tintPurple,
            title:
                '${wallet.plan} plan · ${wallet.jobCredits} job credits left',
            subtitle: 'Upgrade for more job posts and features',
            onTap: () => context.push(RoutePaths.plans),
          ),
          const SectionLabel('Recent Transactions'),
          Row(
            children: [
              for (final (i, l) in const ['All', 'Credits', 'Debits'].indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: PillChip(
                    label: l,
                    height: 21,
                    selected: _filter == i,
                    onTap: () => setState(() => _filter = i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          for (final t in txs) ...[
            SoftCard(
              padding: const EdgeInsets.fromLTRB(11, 9, 12, 9),
              child: Row(
                children: [
                  IconBubble(
                    icon: t.icon,
                    color: t.isCredit ? AppColors.tintGreen : AppColors.tintRed,
                    size: 34,
                    iconSize: 16,
                    circle: false,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: headingColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.date,
                          style: TextStyle(
                            fontSize: 9,
                            color: context.textSubColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${t.isCredit ? '+' : '-'} ${formatRupees(t.amount)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: t.isCredit
                          ? AppColors.tintGreen
                          : AppColors.tintRed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.solid = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final fg = solid ? AppColors.brandNavy : Colors.white;
    return Material(
      color: solid ? Colors.white : Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: SizedBox(
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
