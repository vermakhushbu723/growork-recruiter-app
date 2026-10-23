import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/providers/activity_providers.dart';
import 'call_screen.dart';
import 'chat_room_screen.dart';

enum _ChatKind { candidate, freelancer, intern, team }

extension on _ChatKind {
  String get label => switch (this) {
    _ChatKind.candidate => 'Candidate',
    _ChatKind.freelancer => 'Freelancer',
    _ChatKind.intern => 'Intern',
    _ChatKind.team => 'Team',
  };

  Color get color => switch (this) {
    _ChatKind.candidate => AppColors.tintBlue,
    _ChatKind.freelancer => AppColors.tintGreen,
    _ChatKind.intern => AppColors.tintOrange,
    _ChatKind.team => AppColors.tintPurple,
  };
}

class _ChatPreview {
  const _ChatPreview({
    this.conversationId = '',
    this.otherId = '',
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.kind,
    required this.details,
    this.unread = 0,
    this.isPerson = false,
  });
  final String name;
  final String lastMessage;
  final String time;
  final _ChatKind kind;

  /// Small icon + label items under the message (meeting, attachments…).
  final List<(IconData, String)> details;
  final int unread;
  /// Presence isn't tracked yet.
  final bool isOnline = false;

  /// People get a round photo-style avatar; companies get their logo.
  final bool isPerson;

  /// Solid initials avatar (overrides the logo) when set.
  final Color? avatarColor = null;
  final String? initials = null;
  final String conversationId;
  final String otherId;

  factory _ChatPreview.fromSummary(ChatSummary c) => _ChatPreview(
    conversationId: c.id,
    otherId: c.otherId,
    name: c.name,
    lastMessage: c.lastMessage.isEmpty ? 'No messages yet' : c.lastMessage,
    time: c.timeLabel,
    kind: switch (c.role) {
      'freelancer' => _ChatKind.freelancer,
      'student' => _ChatKind.intern,
      _ => _ChatKind.candidate,
    },
    unread: c.unread,
    isPerson: true,
    details: [
      if (c.context.isNotEmpty) (Icons.work_outline_rounded, c.context),
    ],
  );
}

/// Filter chips: label → which chats it keeps.
final _filters = <(String, bool Function(_ChatPreview))>[
  ('All', (_) => true),
  ('Unread', (c) => c.unread > 0),
  (
    'Candidates',
    (c) => c.kind == _ChatKind.candidate || c.kind == _ChatKind.intern,
  ),
  ('Freelancers', (c) => c.kind == _ChatKind.freelancer),
  ('Team', (c) => c.kind == _ChatKind.team),
];

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  int _filter = 0;
  String _query = '';
  bool _unreadFirst = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chatListProvider);
    final all = [
      for (final c in async.value ?? const <ChatSummary>[])
        _ChatPreview.fromSummary(c),
    ];
    final unreadCount = all.fold(0, (sum, c) => sum + c.unread);
    final q = _query.toLowerCase();
    final chats = all
        .where(_filters[_filter].$2)
        .where(
          (c) =>
              q.isEmpty ||
              c.name.toLowerCase().contains(q) ||
              c.lastMessage.toLowerCase().contains(q),
        )
        .toList();
    if (_unreadFirst) {
      chats.sort((a, b) => b.unread.compareTo(a.unread));
    }

    return Scaffold(
      floatingActionButton: SizedBox(
        width: 43,
        height: 43,
        child: FloatingActionButton(
          onPressed: () => context.push(RoutePaths.newChat),
          elevation: 4,
          child: const Icon(Icons.add_comment_outlined, size: 20),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(chatListProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 10, 12, 0),
                  // Buttons sit on the title line; the subtitle runs underneath.
                  child: Stack(
                    children: [
                      const PageHeader(
                        title: 'Chat & Messages',
                        titleSize: 20,
                        subtitle:
                            'Talk to candidates, freelancers and your team',
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Row(
                          children: [
                            CircleActionButton(
                              icon: Icons.videocam_outlined,
                              onTap: () => all.isEmpty
                                  ? context.showSnackBar('No one to call yet')
                                  : context.push(
                                      RoutePaths.call,
                                      extra: CallArgs(
                                        name: all.first.name,
                                        video: true,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 9),
                            CircleActionButton(
                              icon: Icons.notifications_none_rounded,
                              badge: ref.watch(notificationsProvider).unread,
                              onTap: () =>
                                  context.push(RoutePaths.notifications),
                            ),
                            const SizedBox(width: 9),
                            CircleActionButton(
                              icon: Icons.more_vert_rounded,
                              onTap: () => _showMoreSheet(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
                  child: SearchFilterBar(
                    height: 33,
                    fontSize: 10,
                    hint: 'Search conversations...',
                    showFilterDot: _unreadFirst,
                    onChanged: (v) => setState(() => _query = v),
                    onFilter: () => _showSortSheet(context),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ChipScroller(
                  padding: 12,
                  children: [
                    for (int i = 0; i < _filters.length; i++)
                      PillChip(
                        label: _filters[i].$1,
                        height: 20,
                        selected: _filter == i,
                        badge: _filters[i].$1 == 'Unread' ? unreadCount : null,
                        onTap: () => setState(() => _filter = i),
                      ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 9)),
              if (async.isLoading && !async.hasValue)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (async.hasError && !async.hasValue)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Couldn’t load chats',
                    message: async.error.toString(),
                    actionLabel: 'Try again',
                    onAction: () => ref.invalidate(chatListProvider),
                  ),
                )
              else if (chats.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No conversations',
                    message: 'Message a candidate or freelancer to start one',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 70),
                  sliver: SliverList.separated(
                    itemCount: chats.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) => _ChatTile(
                      chat: chats[index],
                      onBack: () => ref.invalidate(chatListProvider),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Sort conversations',
        children: [
          SheetOption(
            icon: Icons.schedule_rounded,
            label: 'Most recent',
            selected: !_unreadFirst,
            onTap: () {
              setState(() => _unreadFirst = false);
              Navigator.pop(sheetContext);
            },
          ),
          SheetOption(
            icon: Icons.mark_chat_unread_outlined,
            label: 'Unread first',
            selected: _unreadFirst,
            onTap: () {
              setState(() => _unreadFirst = true);
              Navigator.pop(sheetContext);
            },
          ),
        ],
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Chat options',
        children: [
          SheetOption(
            icon: Icons.done_all_rounded,
            label: 'Mark all as read',
            onTap: () {
              Navigator.pop(sheetContext);
              context.runApi(() async {
                await api.post('/chats/read-all');
                ref.invalidate(chatListProvider);
              }, success: 'All conversations marked as read');
            },
          ),
          SheetOption(
            icon: Icons.add_comment_outlined,
            label: 'New conversation',
            onTap: () {
              Navigator.pop(sheetContext);
              context.push(RoutePaths.newChat);
            },
          ),
          SheetOption(
            icon: Icons.settings_outlined,
            label: 'Chat settings',
            onTap: () {
              Navigator.pop(sheetContext);
              context.push(RoutePaths.settings);
            },
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat, this.onBack});

  final _ChatPreview chat;

  /// Called after returning from the conversation (unread counts change).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unread > 0;
    final sub = context.textSubColor;
    return SoftCard(
      radius: 9,
      padding: const EdgeInsets.fromLTRB(13, 9, 9, 8),
      onTap: () => context
          .push(
            RoutePaths.chatRoom,
            extra: ChatTarget(
              conversationId: chat.conversationId,
              userId: chat.otherId,
              name: chat.name,
            ),
          )
          .then((_) => onBack?.call()),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (chat.avatarColor != null)
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: chat.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat.initials ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (chat.initials ?? '').length > 1 ? 15 : 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (chat.isPerson)
                UserAvatar(name: chat.name, size: 40)
              else
                CompanyLogo(name: chat.name, size: 40, circle: true),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 8.5,
                  height: 8.5,
                  decoration: BoxDecoration(
                    color: chat.isOnline
                        ? AppColors.tintGreen
                        : const Color(0xFF9AA3B2),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.surfaceColor, width: 1.3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        chat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: headingColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TintTag(
                      chat.kind.label,
                      color: chat.kind.color,
                      height: 16.5,
                      fontSize: 8.5,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  chat.lastMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    color: hasUnread ? headingColor(context) : sub,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (int i = 0; i < chat.details.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(fontSize: 8, color: sub),
                          ),
                        ),
                      Icon(chat.details[i].$1, size: 10.5, color: sub),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          chat.details[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 8.5, color: sub),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(chat.time, style: TextStyle(fontSize: 9, color: sub)),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasUnread)
                      Container(
                        width: 17,
                        height: 17,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.tintBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${chat.unread}',
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 15, color: sub),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
