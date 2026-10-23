import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../freelance/data/project_models.dart';
import '../../../freelance/providers/client_projects_provider.dart';
import '../../../jobs/data/job_post_model.dart';
import '../../../jobs/providers/recruitment_provider.dart';
import '../../data/talent_model.dart';
import '../widgets/talent_card.dart';

class TalentProfileScreen extends ConsumerWidget {
  const TalentProfileScreen({super.key, required this.talentId});

  final String talentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(talentProfileProvider(talentId));
    final t = async.value;
    if (t == null) {
      return LoadingView(
        error: async.hasError ? async.error.toString() : null,
        onRetry: () => ref.invalidate(talentProfileProvider(talentId)),
      );
    }
    final saved = ref.watch(savedTalentProvider).contains(t.id);
    final sub = context.textSubColor;
    final isFreelancer = t.kind == TalentKind.freelancer;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFreelancer ? 'Freelancer Profile' : 'Candidate Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => context.showSnackBar('Profile link copied'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(13),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(name: t.name, size: 70),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: t.available
                              ? AppColors.tintGreen
                              : const Color(0xFF9AA3B2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.surfaceColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  t.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: headingColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${t.headline} · ${t.location}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: sub),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    TintTag(
                      t.kind.label,
                      color: talentKindColor(t.kind),
                      height: 17,
                    ),
                    TintTag(
                      t.available ? 'Available now' : 'Not available',
                      color: t.available
                          ? AppColors.tintGreen
                          : AppColors.textSub,
                      height: 17,
                    ),
                    TintTag(
                      '${t.rating} ★',
                      color: AppColors.brandAmber,
                      height: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 3.1,
            children: [
              StatBox(
                label: isFreelancer ? 'Hourly rate' : 'Expected salary',
                value: t.rate,
                icon: Icons.payments_outlined,
                color: AppColors.tintGreen,
              ),
              StatBox(
                label: 'Experience',
                value: t.experience,
                icon: Icons.work_outline_rounded,
                color: AppColors.tintBlue,
              ),
              StatBox(
                label: 'Rating',
                value: '${t.rating} / 5',
                icon: Icons.star_border_rounded,
                color: AppColors.brandAmber,
              ),
              StatBox(
                label: isFreelancer ? 'Jobs done' : 'Education',
                value: isFreelancer ? '${t.jobsDone}' : t.education,
                icon: isFreelancer
                    ? Icons.task_alt_rounded
                    : Icons.school_outlined,
                color: AppColors.tintPurple,
              ),
            ],
          ),
          const SectionLabel('About'),
          SoftCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              t.about,
              style: TextStyle(fontSize: 10.5, height: 1.5, color: sub),
            ),
          ),
          const SectionLabel('Skills'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in t.skills)
                TintTag(s, color: AppColors.tintBlue, height: 20, fontSize: 9),
            ],
          ),
          if (t.portfolio.isNotEmpty) ...[
            const SectionLabel('Portfolio'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              childAspectRatio: 1.6,
              children: [
                for (final (i, item) in t.portfolio.indexed)
                  SoftCard(
                    padding: EdgeInsets.zero,
                    onTap: () => context.showSnackBar('Opening $item'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(9),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  [
                                    AppColors.tintBlue,
                                    AppColors.tintPurple,
                                    AppColors.tintTeal,
                                  ][i % 3],
                                  AppColors.brandSky,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            item,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: headingColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const SectionLabel('Details'),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                InfoRow(
                  label: 'Education',
                  value: t.education,
                  icon: Icons.school_outlined,
                ),
                InfoRow(
                  label: 'Location',
                  value: t.location,
                  icon: Icons.location_on_outlined,
                ),
                InfoRow(
                  label: 'Looking for',
                  value: isFreelancer ? 'Freelance projects' : 'Full-time jobs',
                  icon: Icons.search_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 40),
                ),
                onPressed: () => context.runApi(
                  () => ref.read(savedTalentProvider.notifier).toggle(t.id),
                  success: saved ? 'Removed from saved' : 'Saved to your list',
                ),
                child: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  RoutePaths.chatRoom,
                  extra: ChatTarget(userId: t.id, name: t.name),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                label: const Text('Message'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _invite(context, ref, t),
                icon: const Icon(Icons.send_rounded, size: 15),
                label: const Text('Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _invite(BuildContext context, WidgetRef ref, TalentModel t) {
    final isFreelancer = t.kind == TalentKind.freelancer;
    final jobs = ref
        .read(recruitmentProvider)
        .jobs
        .where((j) => j.status == JobPostStatus.active)
        .toList();
    final projects = ref
        .read(clientProjectsProvider)
        .projects
        .where((p) => p.status == ProjectStatus.open)
        .toList();
    final options = <(IconData, String, String)>[
      if (isFreelancer)
        for (final p in projects) (Icons.laptop_mac_outlined, p.title, p.id)
      else
        for (final j in jobs) (Icons.work_outline_rounded, j.title, j.id),
    ];
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
        child: SheetBody(
          title: isFreelancer ? 'Invite to a project' : 'Invite to apply',
          subtitle: 'Pick where to invite ${t.name.split(' ').first}',
          children: [
            if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  isFreelancer
                      ? 'You have no open projects. Post one first.'
                      : 'You have no active jobs. Post one first.',
                  style: TextStyle(fontSize: 10, color: context.textSubColor),
                ),
              ),
            for (final o in options)
              SheetOption(
                icon: o.$1,
                label: o.$2,
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.runApi(
                    () => inviteTalent(
                      t.id,
                      jobId: isFreelancer ? null : o.$3,
                      projectId: isFreelancer ? o.$3 : null,
                    ),
                    success: 'Invitation sent to ${t.name}',
                  );
                },
              ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                context.push(
                  isFreelancer ? RoutePaths.postProject : RoutePaths.postJob,
                );
              },
              icon: const Icon(Icons.add_rounded, size: 15),
              label: Text(
                isFreelancer ? 'Post a new project' : 'Post a new job',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
