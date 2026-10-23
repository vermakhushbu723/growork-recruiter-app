import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/animations/tap_scale.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/models/account_type.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../freelance/providers/client_projects_provider.dart';
import '../../../jobs/providers/recruitment_provider.dart';
import '../widgets/profile_menu_tile.dart';

/// Profile tab: the company page job seekers see, plus account menu.
class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final hiring = ref.watch(recruitmentProvider);
    final client = ref.watch(clientProjectsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(13.5, 2, 13.5, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: PageHeader(
                title: 'Company Profile',
                subtitle: 'Manage your company page and account',
                trailing: IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 19,
                    color: context.textMainColor,
                  ),
                  onPressed: () => context.push(RoutePaths.settings),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CompanyHeroCard(user: user),
            const SizedBox(height: 10),
            _CompletionCard(value: user?.profileCompletion ?? 0),
            const SizedBox(height: 11),
            _StatsCard(
              stats: [
                (
                  icon: Icons.work_outline_rounded,
                  value: '${hiring.activeJobs.length}',
                  label: 'Active Jobs',
                  color: AppColors.tintBlue,
                  route: RoutePaths.jobs,
                ),
                (
                  icon: Icons.verified_outlined,
                  value: '${hiring.totalHired}',
                  label: 'Hired',
                  color: AppColors.tintGreen,
                  route: RoutePaths.analytics,
                ),
                (
                  icon: Icons.laptop_mac_outlined,
                  value: '${client.projects.length}',
                  label: 'Projects',
                  color: AppColors.tintOrange,
                  route: RoutePaths.projects,
                ),
                (
                  icon: Icons.visibility_outlined,
                  value: '${user?.company.pageViews ?? 0}',
                  label: 'Page Views',
                  color: AppColors.tintPurple,
                  route: RoutePaths.analytics,
                ),
              ],
            ),
            if (user != null) ...[
              const SizedBox(height: 11),
              SoftCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About ${user.company.name}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: context.textMainColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.company.about,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        height: 1.45,
                        color: context.textSubColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Meta(Icons.language_rounded, user.company.website),
                        _Meta(Icons.groups_outlined, user.company.size),
                        _Meta(
                          Icons.calendar_today_outlined,
                          'Founded ${user.company.founded}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 1),
              child: Text(
                'Manage Account',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: context.textMainColor,
                ),
              ),
            ),
            const SizedBox(height: 9),
            ..._menu(context, ref),
          ],
        ),
      ),
    );
  }

  List<Widget> _menu(BuildContext context, WidgetRef ref) {
    final items = [
      ProfileMenuTile(
        icon: Icons.business_outlined,
        iconColor: AppColors.tintBlue,
        label: 'Edit Company Page',
        subtitle: 'Logo, about, industry and verification',
        onTap: () => context.push(RoutePaths.editCompany),
      ),
      ProfileMenuTile(
        icon: Icons.person_outline_rounded,
        iconColor: AppColors.tintOrange,
        label: 'My Account',
        subtitle: 'Your name, designation and contact',
        onTap: () => context.push(RoutePaths.editProfile),
      ),
      ProfileMenuTile(
        icon: Icons.groups_outlined,
        iconColor: AppColors.tintPurple,
        label: 'Team Members',
        subtitle: 'Invite recruiters and hiring managers',
        onTap: () => context.push(RoutePaths.team),
      ),
      ProfileMenuTile(
        icon: Icons.insights_outlined,
        iconColor: AppColors.tintRed,
        label: 'Hiring Analytics',
        subtitle: 'Views, applicants and hiring funnel',
        onTap: () => context.push(RoutePaths.analytics),
      ),
      ProfileMenuTile(
        icon: Icons.workspace_premium_outlined,
        iconColor: AppColors.tintTeal,
        label: 'Plans & Credits',
        subtitle: 'Job post credits and premium features',
        onTap: () => context.push(RoutePaths.plans),
      ),
      ProfileMenuTile(
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.tintGreen,
        label: 'Wallet & Payments',
        subtitle: 'Balance, escrow and invoices',
        onTap: () => context.push(RoutePaths.wallet),
      ),
      ProfileMenuTile(
        icon: Icons.bookmark_border_rounded,
        iconColor: AppColors.tintRed,
        label: 'Saved Talent',
        subtitle: 'Bookmarked candidates and freelancers',
        onTap: () => context.push(RoutePaths.savedTalent),
      ),
      ProfileMenuTile(
        icon: Icons.star_border_rounded,
        iconColor: AppColors.brandAmber,
        label: 'Reviews & Ratings',
        subtitle: 'What freelancers and candidates say',
        onTap: () => context.push(RoutePaths.reviews),
      ),
      ProfileMenuTile(
        icon: Icons.settings_outlined,
        iconColor: AppColors.tintBlue,
        label: 'Settings',
        subtitle: 'Notifications, privacy and security',
        onTap: () => context.push(RoutePaths.settings),
      ),
      ProfileMenuTile(
        icon: Icons.logout_rounded,
        iconColor: AppColors.error,
        destructive: true,
        label: 'Logout',
        subtitle: 'Sign out of your account',
        onTap: () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go(RoutePaths.login);
        },
      ),
    ];
    return [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(height: 4.5),
        items[i],
      ],
    ];
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: context.accentColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 9, color: headingColor(context)),
        ),
      ],
    );
  }
}

class _CompanyHeroCard extends StatelessWidget {
  const _CompanyHeroCard({required this.user});

  final RecruiterUser? user;

  @override
  Widget build(BuildContext context) {
    final company = user?.company ?? const CompanyModel();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF05308C), Color(0xFF0B47B8), Color(0xFF0A3A9A)],
        ),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -60,
            child: Container(
              width: 200,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CompanyLogo(name: company.name, size: 70),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -2,
                      child: TapScale(
                        onTap: () => context.push(RoutePaths.editCompany),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              company.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (company.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF38B6FF),
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${company.industry} · ${company.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                      ),
                      if (user != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${user!.name} · ${user!.designation}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 10.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (user != null)
                            _HeroChip(user!.accountType.label, solid: true),
                          _HeroChip(company.size),
                          _HeroChip(
                            '+ Edit',
                            onTap: () => context.push(RoutePaths.editCompany),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 13,
            top: 14,
            child: TapScale(
              onTap: () => context.push(RoutePaths.editCompany),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.label, {this.solid = false, this.onTap});

  final String label;
  final bool solid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: solid ? Colors.white : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: solid
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: solid ? AppColors.primary : Colors.white,
          fontSize: 8,
          fontWeight: solid ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
    return onTap == null ? chip : TapScale(onTap: onTap, child: chip);
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Page Strength',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: context.textMainColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Complete pages get up to 3× more applicants',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: context.textSubColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(value * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: context.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: context.tagBgColor,
              color: AppColors.primary,
            ),
          ),
          if (value < 1) ...[
            const SizedBox(height: 8),
            Material(
              color: context.tagBgColor,
              borderRadius: BorderRadius.circular(7),
              child: InkWell(
                borderRadius: BorderRadius.circular(7),
                onTap: () => context.push(RoutePaths.editCompany),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 6.5,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.track_changes_rounded,
                        size: 15,
                        color: context.accentColor,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          'Complete Company Page',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: context.accentColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: context.textSubColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final List<
    ({IconData icon, String value, String label, Color color, String route})
  >
  stats;

  static const _tabs = {RoutePaths.jobs, RoutePaths.projects};

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  indent: 8,
                  endIndent: 8,
                  color: context.borderColor,
                ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _tabs.contains(stats[i].route)
                      ? context.go(stats[i].route)
                      : context.push(stats[i].route),
                  child: Column(
                    children: [
                      IconBubble(
                        icon: stats[i].icon,
                        color: stats[i].color,
                        size: 31,
                        iconSize: 15,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stats[i].value,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: context.textMainColor,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          stats[i].label,
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: context.textSubColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
