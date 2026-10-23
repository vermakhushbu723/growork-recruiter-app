import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Blue hero card on the dashboard (same look as the user app's wallet
/// card): live job count, new applicants and the key hiring numbers.
class HiringOverviewCard extends StatelessWidget {
  const HiringOverviewCard({
    super.key,
    required this.activeJobs,
    required this.newApplicants,
    required this.openProjects,
    required this.interviews,
    required this.walletBalance,
  });

  final int activeJobs;
  final int newApplicants;
  final int openProjects;
  final int interviews;
  final String walletBalance;

  @override
  Widget build(BuildContext context) {
    final white80 = Colors.white.withValues(alpha: 0.82);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF023DA3), Color(0xFF0B4CC0), Color(0xFF0A3C9E)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(right: 12, top: 10, child: _BriefcaseArt()),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 9),
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
                        Icons.work_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Active Job Posts',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$activeJobs',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 29.5,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9F4E2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              size: 13,
                              color: Color(0xFF0B7A47),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '+$newApplicants new applicants',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0B7A47),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    WhitePillButton(
                      label: 'Post Job',
                      height: 28,
                      fontSize: 10,
                      onTap: () => context.push(RoutePaths.postJob),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Container(
                  height: 0.8,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 7),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.laptop_mac_rounded,
                          label: 'Open Projects',
                          value: '$openProjects',
                          labelColor: white80,
                          onTap: () => context.go(RoutePaths.projects),
                        ),
                      ),
                      _divider(),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.event_rounded,
                          label: 'Interviews',
                          value: '$interviews',
                          labelColor: white80,
                          onTap: () => context.push(RoutePaths.interviews),
                        ),
                      ),
                      _divider(),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Wallet',
                          value: walletBalance,
                          labelColor: white80,
                          onTap: () => context.push(RoutePaths.wallet),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => VerticalDivider(
    width: 14,
    indent: 2,
    endIndent: 2,
    color: Colors.white.withValues(alpha: 0.22),
  );
}

/// Briefcase with a check badge, drawn with shapes.
class _BriefcaseArt extends StatelessWidget {
  const _BriefcaseArt();

  @override
  Widget build(BuildContext context) {
    Widget glow(double s, double a) => Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: a),
      ),
    );

    return SizedBox(
      width: 112,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, top: 44, child: glow(28, 0.1)),
          Positioned(left: 24, top: 0, child: glow(28, 0.12)),
          Positioned(
            left: 46,
            top: 18,
            child: Container(
              width: 24,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: 28,
            child: Transform.rotate(
              angle: -0.04,
              child: Container(
                width: 58,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3F7BEA), Color(0xFF1C4FC4)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 72,
            top: 8,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF55D68F), Color(0xFF12A15E)],
                ),
                border: Border.all(color: const Color(0xFFBDF2D8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: labelColor,
                    fontSize: 8.5,
                    height: 1.3,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
