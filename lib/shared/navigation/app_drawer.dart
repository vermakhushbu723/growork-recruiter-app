import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/route_paths.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/animations/fade_slide_up.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../models/account_type.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  /// Bottom-nav tabs are switched with `go`; other pages are pushed.
  static const _tabRoutes = {
    RoutePaths.home,
    RoutePaths.jobs,
    RoutePaths.projects,
    RoutePaths.chat,
    RoutePaths.profile,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final currentRoute = GoRouterState.of(context).uri.toString();

    final menuItems = <({IconData icon, String label, String route})>[
      (
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        route: RoutePaths.home,
      ),
      (
        icon: Icons.work_outline_rounded,
        label: 'My Job Posts',
        route: RoutePaths.jobs,
      ),
      (
        icon: Icons.laptop_mac_outlined,
        label: 'My Freelance Projects',
        route: RoutePaths.projects,
      ),
      (
        icon: Icons.person_search_outlined,
        label: 'Find Talent',
        route: RoutePaths.talentSearch,
      ),
      (
        icon: Icons.event_note_outlined,
        label: 'Interviews',
        route: RoutePaths.interviews,
      ),
      (
        icon: Icons.handshake_outlined,
        label: 'Contracts',
        route: RoutePaths.contracts,
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Chat & Messages',
        route: RoutePaths.chat,
      ),
      (
        icon: Icons.insights_outlined,
        label: 'Hiring Analytics',
        route: RoutePaths.analytics,
      ),
      (
        icon: Icons.account_balance_wallet_outlined,
        label: 'Wallet & Payments',
        route: RoutePaths.wallet,
      ),
      (
        icon: Icons.workspace_premium_outlined,
        label: 'Plans & Credits',
        route: RoutePaths.plans,
      ),
      (
        icon: Icons.bookmark_border_rounded,
        label: 'Saved Talent',
        route: RoutePaths.savedTalent,
      ),
      (
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        route: RoutePaths.notifications,
      ),
      (
        icon: Icons.settings_outlined,
        label: 'Settings',
        route: RoutePaths.settings,
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (user?.name ?? 'R').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.name ?? AppStrings.appName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.company.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              user.accountType.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isActive = currentRoute == item.route;
                  return FadeSlideUp(
                    index: index,
                    stagger: const Duration(milliseconds: 30),
                    offset: 14,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? context.tagBgColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Icon(
                            item.icon,
                            color: isActive
                                ? context.accentColor
                                : context.textSubColor,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: isActive
                                  ? context.accentColor
                                  : context.textMainColor,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _tabRoutes.contains(item.route)
                                ? context.go(item.route)
                                : context.push(item.route);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(RoutePaths.login);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
