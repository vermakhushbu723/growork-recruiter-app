import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../chat/presentation/screens/call_screen.dart';
import '../../data/job_post_model.dart';
import '../../providers/recruitment_provider.dart';

class InterviewsScreen extends ConsumerWidget {
  const InterviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(recruitmentProvider).interviews;
    List<Interview> by(InterviewStatus s) =>
        all.where((i) => i.status == s).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final upcoming = by(InterviewStatus.scheduled);
    final completed = by(InterviewStatus.completed);
    final cancelled = by(InterviewStatus.cancelled);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Interviews'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Upcoming (${upcoming.length})'),
              Tab(text: 'Done (${completed.length})'),
              Tab(text: 'Cancelled (${cancelled.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _InterviewList(
              interviews: upcoming,
              emptyTitle: 'No upcoming interviews',
              emptyMessage:
                  'Shortlist candidates and schedule interviews from their profile.',
            ),
            _InterviewList(
              interviews: completed,
              emptyTitle: 'No completed interviews yet',
            ),
            _InterviewList(
              interviews: cancelled,
              emptyTitle: 'No cancelled interviews',
            ),
          ],
        ),
      ),
    );
  }
}

class _InterviewList extends ConsumerWidget {
  const _InterviewList({
    required this.interviews,
    required this.emptyTitle,
    this.emptyMessage,
  });

  final List<Interview> interviews;
  final String emptyTitle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (interviews.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_outlined,
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: emptyMessage == null ? null : 'View Applicants',
        onAction: emptyMessage == null
            ? null
            : () => context.push(RoutePaths.applicants),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 20),
      itemCount: interviews.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _InterviewCard(interview: interviews[i]),
    );
  }
}

class _InterviewCard extends ConsumerWidget {
  const _InterviewCard({required this.interview});

  final Interview interview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iv = interview;
    final sub = context.textSubColor;
    final scheduled = iv.status == InterviewStatus.scheduled;
    return SoftCard(
      onTap: () =>
          context.push(RoutePaths.applicantProfile, extra: iv.applicantId),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: iv.status.color.withValues(
                    alpha: context.isDark ? 0.18 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM').format(iv.dateTime).toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: iv.status.color,
                      ),
                    ),
                    Text(
                      '${iv.dateTime.day}',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: iv.status.color,
                      ),
                    ),
                    Text(
                      DateFormat('EEE').format(iv.dateTime),
                      style: TextStyle(fontSize: 8, color: iv.status.color),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            iv.candidateName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: headingColor(context),
                            ),
                          ),
                        ),
                        StatusPill(
                          label: iv.status.label,
                          color: iv.status.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${iv.jobTitle} · ${iv.round}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9.5, color: sub),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 11, color: sub),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('h:mm a').format(iv.dateTime),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: headingColor(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(iv.mode.icon, size: 11, color: sub),
                        const SizedBox(width: 3),
                        Text(
                          iv.mode.label,
                          style: TextStyle(fontSize: 9, color: sub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 11,
                          color: sub,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            'Interviewer: ${iv.interviewer}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 9, color: sub),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (scheduled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: context.tagBgColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      iv.link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: context.accentColor),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'More',
                  icon: const Icon(Icons.more_horiz_rounded, size: 18),
                  onPressed: () => _showActions(context, ref),
                ),
                ArrowButton(
                  label: iv.mode == InterviewMode.inPerson ? 'Details' : 'Join',
                  height: 27,
                  onTap: () => iv.mode == InterviewMode.inPerson
                      ? context.push(
                          RoutePaths.applicantProfile,
                          extra: iv.applicantId,
                        )
                      : context.push(
                          RoutePaths.call,
                          extra: CallArgs(
                            name: iv.candidateName,
                            video: iv.mode == InterviewMode.video,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(recruitmentProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Interview options',
        subtitle: '${interview.candidateName} · ${interview.round}',
        children: [
          SheetOption(
            icon: Icons.task_alt_rounded,
            label: 'Mark as completed',
            onTap: () {
              Navigator.pop(sheetContext);
              context.runApi(
                () => notifier.setInterviewStatus(
                  interview.id,
                  InterviewStatus.completed,
                ),
                success: 'Interview marked as completed',
              );
            },
          ),
          SheetOption(
            icon: Icons.edit_calendar_outlined,
            label: 'Reschedule',
            onTap: () {
              Navigator.pop(sheetContext);
              context
                  .runApi(
                    () => notifier.setInterviewStatus(
                      interview.id,
                      InterviewStatus.cancelled,
                    ),
                  )
                  .then((ok) {
                    if (ok && context.mounted) {
                      context.push(
                        RoutePaths.scheduleInterview,
                        extra: interview.applicantId,
                      );
                    }
                  });
            },
          ),
          SheetOption(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message candidate',
            onTap: () {
              Navigator.pop(sheetContext);
              context.push(
                RoutePaths.chatRoom,
                extra: ChatTarget(
                  userId: interview.candidateId,
                  name: interview.candidateName,
                  context: interview.jobTitle,
                ),
              );
            },
          ),
          SheetOption(
            icon: Icons.event_busy_outlined,
            label: 'Cancel interview',
            destructive: true,
            onTap: () {
              Navigator.pop(sheetContext);
              context.runApi(
                () => notifier.setInterviewStatus(
                  interview.id,
                  InterviewStatus.cancelled,
                ),
                success: 'Interview cancelled · candidate notified',
              );
            },
          ),
        ],
      ),
    );
  }
}
