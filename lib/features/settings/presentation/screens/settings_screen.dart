import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/models/account_type.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Switch bound to a server-side setting.
  Widget _setting(String key, {bool fallback = true}) {
    final settings = ref.read(settingsProvider.notifier);
    return _switch(
      settings.flag(key, fallback: fallback),
      (v) => context.runApi(() => settings.set(key, v)),
    );
  }

  void _toggle(String key, {bool fallback = true}) {
    final settings = ref.read(settingsProvider.notifier);
    context.runApi(
      () => settings.set(key, !settings.flag(key, fallback: fallback)),
    );
  }

  Widget _switch(bool value, ValueChanged<bool> onChanged) => Transform.scale(
    scale: 0.8,
    child: Switch(value: value, onChanged: onChanged),
  );

  Widget _value(String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(text, style: TextStyle(fontSize: 10, color: context.textSubColor)),
      Icon(Icons.chevron_right_rounded, size: 15, color: context.textSubColor),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    ref.watch(settingsProvider);
    final user = ref.watch(authProvider).user;
    const gap = SizedBox(height: 6);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 0, 13, 20),
        children: [
          const SectionLabel('Appearance'),
          MenuTile(
            icon: Icons.dark_mode_outlined,
            color: AppColors.tintPurple,
            title: 'Dark Mode',
            subtitle: 'Easier on the eyes at night',
            onTap: () => ref.read(themeModeProvider.notifier).toggle(!isDark),
            trailing: _switch(
              isDark,
              (v) => ref.read(themeModeProvider.notifier).toggle(v),
            ),
          ),
          gap,
          MenuTile(
            icon: Icons.language_rounded,
            color: AppColors.tintBlue,
            title: 'Language',
            subtitle: 'App display language',
            onTap: () => context.push(RoutePaths.language),
            trailing: _value(ref.watch(settingsProvider.notifier).language),
          ),
          const SectionLabel('Account'),
          MenuTile(
            icon: Icons.person_outline_rounded,
            color: AppColors.tintBlue,
            title: 'My Account',
            subtitle: 'Name, designation, email and phone',
            onTap: () => context.push(RoutePaths.editProfile),
          ),
          gap,
          MenuTile(
            icon: Icons.business_outlined,
            color: AppColors.tintOrange,
            title: 'Company Page',
            subtitle: 'Logo, about, industry and GSTIN',
            onTap: () => context.push(RoutePaths.editCompany),
          ),
          gap,
          MenuTile(
            icon: Icons.switch_account_outlined,
            color: AppColors.tintTeal,
            title: 'Hiring For',
            subtitle: 'Jobs, freelance projects or both',
            onTap: () => context.push(RoutePaths.accountType, extra: true),
            trailing: _value(user?.accountType.label ?? ''),
          ),
          gap,
          MenuTile(
            icon: Icons.groups_outlined,
            color: AppColors.tintPurple,
            title: 'Team Members',
            subtitle: 'Invite and manage recruiters',
            onTap: () => context.push(RoutePaths.team),
          ),
          gap,
          MenuTile(
            icon: Icons.lock_reset_outlined,
            color: AppColors.tintOrange,
            title: 'Change Password',
            subtitle: 'Reset via email OTP',
            onTap: () => context.push(RoutePaths.forgotPassword),
          ),
          gap,
          MenuTile(
            icon: Icons.verified_user_outlined,
            color: AppColors.tintGreen,
            title: 'Privacy & Security',
            subtitle: 'Company page visibility, 2-step login',
            onTap: () => context.push(RoutePaths.privacy),
          ),
          const SectionLabel('Billing'),
          MenuTile(
            icon: Icons.workspace_premium_outlined,
            color: AppColors.tintPurple,
            title: 'Plans & Credits',
            subtitle: 'Upgrade or buy job credits',
            onTap: () => context.push(RoutePaths.plans),
          ),
          gap,
          MenuTile(
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.tintGreen,
            title: 'Wallet & Invoices',
            subtitle: 'Balance, escrow and GST invoices',
            onTap: () => context.push(RoutePaths.wallet),
          ),
          const SectionLabel('Notifications'),
          MenuTile(
            icon: Icons.person_add_alt_outlined,
            color: AppColors.tintBlue,
            title: 'New Applicants',
            subtitle: 'When someone applies to your jobs',
            onTap: () => _toggle('applicantAlerts'),
            trailing: _setting('applicantAlerts'),
          ),
          gap,
          MenuTile(
            icon: Icons.description_outlined,
            color: AppColors.tintGreen,
            title: 'Proposals & Milestones',
            subtitle: 'New bids and work submitted for review',
            onTap: () => _toggle('proposalAlerts'),
            trailing: _setting('proposalAlerts'),
          ),
          gap,
          MenuTile(
            icon: Icons.mail_outline_rounded,
            color: AppColors.tintPurple,
            title: 'Weekly Hiring Digest',
            subtitle: 'Email summary of your hiring',
            onTap: () => _toggle('emailDigest'),
            trailing: _setting('emailDigest'),
          ),
          gap,
          MenuTile(
            icon: Icons.quickreply_outlined,
            color: AppColors.tintOrange,
            title: 'Auto-reply to Applicants',
            subtitle: 'Send a thank-you message on every application',
            onTap: () => _toggle('autoReply', fallback: false),
            trailing: _setting('autoReply', fallback: false),
          ),
          const SectionLabel('Support'),
          MenuTile(
            icon: Icons.help_outline_rounded,
            color: AppColors.tintTeal,
            title: 'Help & Support',
            subtitle: 'FAQs, contact us, report a problem',
            onTap: () => context.push(RoutePaths.help),
          ),
          gap,
          MenuTile(
            icon: Icons.gavel_outlined,
            color: AppColors.tintBlue,
            title: 'Employer Policy',
            subtitle: 'Fair hiring and posting guidelines',
            onTap: () => context.showSnackBar('Opening employer policy'),
          ),
          gap,
          MenuTile(
            icon: Icons.info_outline_rounded,
            color: AppColors.tintBlue,
            title: 'About Subkamyaab Recruiter',
            subtitle: 'Version 1.0.0',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Subkamyaab Recruiter',
              applicationVersion: '1.0.0',
            ),
          ),
          const SectionLabel('Danger Zone'),
          MenuTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out of this device',
            destructive: true,
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(RoutePaths.login);
            },
          ),
          gap,
          MenuTile(
            icon: Icons.delete_outline_rounded,
            title: 'Delete Company Account',
            subtitle: 'Removes all job posts and data',
            destructive: true,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Company Account'),
        content: const Text(
          'Your account, chats, notifications and wallet history will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              dialogContext.pop();
              final ok = await context.runApi(
                () => ref.read(authProvider.notifier).deleteAccount(),
                success: 'Account deleted',
              );
              if (ok && context.mounted) context.go(RoutePaths.login);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
