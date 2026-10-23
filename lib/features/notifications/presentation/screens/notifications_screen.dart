import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/activity_providers.dart';

/// Icon and tint for each notification type.
(IconData, Color) _style(String type) => switch (type) {
  'applicationReceived' => (Icons.person_add_alt_1_outlined, AppColors.tintBlue),
  'proposalReceived' => (Icons.description_outlined, AppColors.tintGreen),
  'milestoneSubmitted' => (Icons.rate_review_outlined, AppColors.tintOrange),
  'interviewScheduled' => (Icons.event_available_outlined, AppColors.tintPurple),
  'message' => (Icons.chat_bubble_outline_rounded, AppColors.tintTeal),
  'plan' => (Icons.workspace_premium_outlined, AppColors.tintOrange),
  'offerReceived' => (Icons.local_offer_outlined, AppColors.tintRed),
  _ => (Icons.notifications_none_rounded, AppColors.tintBlue),
};

/// Opens the screen a notification is about.
void _open(BuildContext context, AppNotification n) {
  final ref = n.ref;
  switch (n.type) {
    case 'applicationReceived' when ref.isNotEmpty:
      context.push(RoutePaths.applicantProfile, extra: ref);
    case 'proposalReceived' when ref.isNotEmpty:
      context.push(RoutePaths.proposalDetails, extra: ref);
    case 'milestoneSubmitted' ||
            'milestoneFunded' ||
            'milestoneReleased' ||
            'revisionRequested' ||
            'contractEnded'
        when ref.isNotEmpty:
      context.push(RoutePaths.contract, extra: ref);
    case 'message':
      context.go(RoutePaths.chat);
    case 'plan':
      context.push(RoutePaths.plans);
    case 'interviewScheduled':
      context.push(RoutePaths.interviews);
    default:
      context.go(RoutePaths.home);
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final today = state.items.where((n) => n.isToday).toList();
    final earlier = state.items.where((n) => !n.isToday).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unread > 0)
            TextButton(
              onPressed: () => context.runApi(
                notifier.markAllRead,
                success: 'All notifications marked as read',
              ),
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: !state.loaded
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'You’re all caught up',
              message: 'New applicants, proposals and messages show up here',
            )
          : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                children: [
                  if (today.isNotEmpty) ...[
                    const SectionLabel('Today'),
                    for (final n in today) _tile(context, ref, n),
                  ],
                  if (earlier.isNotEmpty) ...[
                    const SectionLabel('Earlier'),
                    for (final n in earlier) _tile(context, ref, n),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, AppNotification n) {
    final unread = !n.isRead;
    final (icon, color) = _style(n.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SoftCard(
        color: unread
            ? Color.alphaBlend(
                context.accentColor.withValues(alpha: 0.05),
                context.surfaceColor,
              )
            : null,
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
        onTap: () {
          if (unread) ref.read(notificationsProvider.notifier).markRead(n.id);
          _open(context, n);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBubble(icon: icon, color: color, size: 36, iconSize: 17),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: headingColor(context),
                          ),
                        ),
                      ),
                      Text(
                        timeAgo(n.createdAt),
                        style: TextStyle(
                          fontSize: 9,
                          color: context.textSubColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.35,
                      color: context.textSubColor,
                    ),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 6),
              Container(
                margin: const EdgeInsets.only(top: 18),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.tintBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
