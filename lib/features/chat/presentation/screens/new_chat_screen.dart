import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/activity_providers.dart';
import 'chat_room_screen.dart';

/// Tag shown next to a contact, from their role on the platform.
(String, Color) _roleTag(String role) => switch (role) {
  'freelancer' => ('Freelancer', AppColors.tintGreen),
  'student' => ('Intern', AppColors.tintOrange),
  'recruiter' || 'both' => ('Recruiter', AppColors.tintBlue),
  'client' => ('Client', AppColors.tintGreen),
  _ => ('Candidate', AppColors.tintBlue),
};

/// Pick a contact to start a new conversation.
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final async = ref.watch(chatContactsProvider);
    final list = (async.value ?? const <ChatContact>[])
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('New Conversation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
        children: [
          SearchFilterBar(
            hint: 'Search candidates and freelancers...',
            height: 34,
            insetFilter: true,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.group_add_outlined,
                  label: 'New Group',
                  color: AppColors.tintPurple,
                  onTap: () => context.showSnackBar('Group chats coming soon'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  color: AppColors.tintGreen,
                  onTap: () => context.push(RoutePaths.help),
                ),
              ),
            ],
          ),
          const SectionLabel('Suggested'),
          for (int i = 0; i < list.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              onTap: () => context.pushReplacement(
                RoutePaths.chatRoom,
                extra: ChatTarget(userId: list[i].id, name: list[i].name),
              ),
              child: Row(
                children: [
                  UserAvatar(name: list[i].name, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      list[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: headingColor(context),
                      ),
                    ),
                  ),
                  TintTag(
                    _roleTag(list[i].role).$1,
                    color: _roleTag(list[i].role).$2,
                    height: 16,
                  ),
                ],
              ),
            ),
          ],
          if (async.isLoading && !async.hasValue)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  async.hasError
                      ? async.error.toString()
                      : 'No contacts yet — people you hire or who apply show up here',
                  style: TextStyle(fontSize: 11, color: context.textSubColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          IconBubble(icon: icon, color: color, size: 32, iconSize: 15),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: headingColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
