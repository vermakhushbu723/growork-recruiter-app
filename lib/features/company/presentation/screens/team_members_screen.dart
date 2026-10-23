import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';

const _roles = ['Admin', 'Recruiter', 'Hiring Manager', 'Viewer'];

Color _roleColor(String role) => switch (role) {
  'Admin' => AppColors.tintPurple,
  'Recruiter' => AppColors.tintBlue,
  'Hiring Manager' => AppColors.tintTeal,
  _ => AppColors.textSub,
};

/// Colleagues who can post jobs, review applicants and chat on behalf of
/// the company.
class TeamMembersScreen extends ConsumerWidget {
  const TeamMembersScreen({super.key});

  void _invite(BuildContext context, WidgetRef ref) {
    final email = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var role = 'Recruiter';
    var busy = false;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Form(
          key: formKey,
          child: SheetBody(
            title: 'Invite team member',
            subtitle: 'They will get an email to join your company workspace',
            children: [
              LabeledField(
                label: 'Work email',
                controller: email,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              ChipGroup(
                label: 'Role',
                options: _roles,
                value: role,
                onChanged: (v) => setSheet(() => role = v),
              ),
              const SizedBox(height: 14),
              LoadingButton(
                label: 'Send Invite',
                loading: busy,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final address = email.text.trim();
                  setSheet(() => busy = true);
                  final ok = await sheetContext.runApi(
                    () => ref
                        .read(authProvider.notifier)
                        .inviteMember(address, role),
                  );
                  if (!sheetContext.mounted) return;
                  setSheet(() => busy = false);
                  if (!ok) return;
                  Navigator.pop(sheetContext);
                  if (context.mounted) {
                    context.showSnackBar('Invite sent to $address');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members =
        ref.watch(authProvider).user?.company.members ?? const <TeamMember>[];
    final notifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
        actions: [
          TextButton.icon(
            onPressed: () => _invite(context, ref),
            icon: const Icon(Icons.person_add_alt_rounded, size: 16),
            label: const Text('Invite'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatBox(
                    label: 'Members',
                    value: '${members.where((m) => !m.pending).length}',
                    icon: Icons.groups_outlined,
                    color: AppColors.tintBlue,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: StatBox(
                    label: 'Pending invites',
                    value: '${members.where((m) => m.pending).length}',
                    icon: Icons.mark_email_unread_outlined,
                    color: AppColors.tintOrange,
                  ),
                ),
              ],
            ),
            const SectionLabel('Your team'),
            for (final m in members) ...[
              SoftCard(
                padding: const EdgeInsets.fromLTRB(11, 9, 6, 9),
                child: Row(
                  children: [
                    UserAvatar(name: m.name, size: 38),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: headingColor(context),
                            ),
                          ),
                          Text(
                            m.pending ? '${m.email} · Invite pending' : m.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: context.textSubColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(label: m.role, color: _roleColor(m.role)),
                    if (!m.isOwner)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        onSelected: (v) async {
                          if (v == 'remove') {
                            final ok = await confirmDialog(
                              context,
                              title: 'Remove ${m.name}?',
                              message:
                                  'They will lose access to your job posts and chats.',
                              confirmLabel: 'Remove',
                              destructive: true,
                            );
                            if (!ok || !context.mounted) return;
                            await context.runApi(
                              () => notifier.removeMember(m.id),
                              success: '${m.name} removed',
                            );
                          } else {
                            await context.runApi(
                              () => notifier.setMemberRole(m.id, v),
                              success: '${m.name} is now $v',
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          for (final r in _roles.where((r) => r != m.role))
                            PopupMenuItem(value: r, child: Text('Make $r')),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text(
                              'Remove',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(width: 10),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
            const SectionLabel('Roles'),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  for (final r in const [
                    ('Admin', 'Everything, including billing and team'),
                    ('Recruiter', 'Post jobs, manage applicants, chat'),
                    ('Hiring Manager', 'Review applicants and interviews'),
                    ('Viewer', 'Read-only access'),
                  ])
                    InfoRow(label: r.$1, value: r.$2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
