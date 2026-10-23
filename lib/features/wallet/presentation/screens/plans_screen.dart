import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../freelance/data/project_models.dart';
import '../../providers/wallet_provider.dart';

/// Hiring plans: job-post credits and premium recruiter features.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Plans & Credits')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          GradientCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current plan',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        wallet.plan,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${wallet.jobCredits} job credits left · renews 1 Nov 2026',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('Choose a plan'),
          for (final plan in hiringPlans) ...[
            _PlanCard(
              plan: plan,
              current: wallet.plan == plan.name,
              onBuy: () => _buy(context, ref, plan),
            ),
            const SizedBox(height: 8),
          ],
          const SectionLabel('Need just a few posts?'),
          MenuTile(
            icon: Icons.confirmation_number_outlined,
            color: AppColors.tintTeal,
            title: 'Single job post · ₹499',
            subtitle: 'One extra credit, valid for 30 days',
            onTap: () => _buy(
              context,
              ref,
              const HiringPlan(
                name: 'Single post',
                price: 499,
                jobCredits: 1,
                features: [],
              ),
              addOn: true,
            ),
          ),
          const SizedBox(height: 6),
          MenuTile(
            icon: Icons.local_fire_department_outlined,
            color: AppColors.urgentTxt,
            title: 'Urgent badge · ₹299',
            subtitle: 'Boost one job to the top for 7 days',
            onTap: () => context.showSnackBar(
              'Open a job post and turn on "Urgent Hiring" to boost it',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    HiringPlan plan, {
    bool addOn = false,
  }) async {
    final ok = await confirmDialog(
      context,
      title: addOn ? 'Buy ${plan.name}?' : 'Switch to ${plan.name}?',
      message: plan.price == 0
          ? 'Switch to the free Starter plan.'
          : '${formatRupees(plan.price)} will be paid from your wallet and ${plan.jobCredits} job credits added.',
      confirmLabel: plan.price == 0
          ? 'Switch'
          : 'Pay ${formatRupees(plan.price)}',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(walletProvider.notifier).buyPlan(plan, addOn: addOn);
      if (context.mounted) {
        context.showSnackBar(
          '${plan.name} activated · ${plan.jobCredits} credits added',
        );
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      context.showSnackBar(e.message, isError: true);
      if (e.status == 402) context.push(RoutePaths.addMoney);
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.current,
    required this.onBuy,
  });

  final HiringPlan plan;
  final bool current;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: plan.popular ? context.accentColor : Colors.transparent,
          width: 1.6,
        ),
      ),
      child: SoftCard(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: headingColor(context),
                  ),
                ),
                const SizedBox(width: 6),
                if (plan.popular)
                  const TintTag(
                    'Most popular',
                    color: AppColors.tintOrange,
                    icon: Icons.star_rounded,
                    height: 16,
                  ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    text: plan.price == 0 ? 'Free' : formatRupees(plan.price),
                    children: [
                      if (plan.price > 0)
                        TextSpan(
                          text: ' /month',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: context.textSubColor,
                          ),
                        ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TickList(plan.features),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: current
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_rounded, size: 15),
                      label: const Text('Current Plan'),
                    )
                  : plan.popular
                  ? ElevatedButton(
                      onPressed: onBuy,
                      child: const Text('Upgrade'),
                    )
                  : OutlinedButton(
                      onPressed: onBuy,
                      child: Text(
                        plan.price == 0 ? 'Switch to Free' : 'Choose Plan',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
