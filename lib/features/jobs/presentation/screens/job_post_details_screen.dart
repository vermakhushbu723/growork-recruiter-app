import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/banners.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/job_post_model.dart';
import '../../providers/recruitment_provider.dart';
import '../widgets/applicant_card.dart';
import '../widgets/job_post_card.dart';
import 'applicants_screen.dart';

class JobPostDetailsScreen extends ConsumerWidget {
  const JobPostDetailsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiring = ref.watch(recruitmentProvider);
    final job = hiring.job(jobId);
    if (job == null) {
      if (!hiring.loaded) return const LoadingView();
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Job post not found',
          message: 'It may have been deleted.',
        ),
      );
    }
    final company = ref.watch(authProvider).user?.company.name ?? 'Company';
    final applicants = hiring.applicantsFor(job.id);
    final sub = context.textSubColor;
    int count(ApplicantStatus s) => hiring.countFor(job.id, s);

    return Scaffold(
      appBar: AppBar(
        title: Text(job.isInternship ? 'Internship Post' : 'Job Post'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(RoutePaths.postJob, extra: job.id),
          ),
          IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showActions(context, ref, job),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    StatusPill(
                      label: job.status.label,
                      color: job.status.color,
                    ),
                  ],
                ),
                CompanyLogo(name: company, size: 56),
                const SizedBox(height: 10),
                Text(
                  job.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: headingColor(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$company · ${job.location}',
                  style: TextStyle(fontSize: 10.5, color: sub),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    TintTag(
                      job.type,
                      color: jobTypeColor(job.type),
                      height: 17,
                    ),
                    TintTag(
                      job.workMode,
                      color: workModeColor(job.workMode),
                      height: 17,
                    ),
                    TintTag(
                      job.level,
                      color: levelColor(job.level),
                      height: 17,
                    ),
                    if (job.isUrgent)
                      const TintTag(
                        'Urgent Hiring',
                        color: AppColors.urgentTxt,
                        icon: Icons.local_fire_department_rounded,
                        height: 17,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Posted ${job.postedAgo} · Closes ${job.deadline}',
                  style: TextStyle(fontSize: 9, color: sub),
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
                label: 'Total views',
                value: '${job.views}',
                icon: Icons.visibility_outlined,
                color: AppColors.tintPurple,
              ),
              StatBox(
                label: 'Applicants',
                value: '${applicants.length}',
                icon: Icons.people_alt_outlined,
                color: AppColors.tintBlue,
              ),
              StatBox(
                label: job.isInternship ? 'Stipend' : 'Salary',
                value: job.shortSalary,
                icon: Icons.payments_outlined,
                color: AppColors.tintGreen,
              ),
              StatBox(
                label: job.isInternship ? 'Duration' : 'Experience',
                value: job.isInternship
                    ? (job.duration ?? '-')
                    : job.experience,
                icon: Icons.work_outline_rounded,
                color: AppColors.tintOrange,
              ),
            ],
          ),
          const SectionLabel('Hiring pipeline'),
          PipelineStrip(
            items: [
              for (final s in ApplicantStatus.values)
                (
                  label: s.label,
                  count: count(s),
                  color: s.color,
                  onTap: () => context.push(
                    RoutePaths.applicants,
                    extra: ApplicantsArgs(jobId: job.id, status: s),
                  ),
                ),
            ],
          ),
          SectionLabel(
            'Latest applicants',
            trailing: applicants.isEmpty
                ? null
                : TextButton(
                    onPressed: () =>
                        context.push(RoutePaths.applicants, extra: job.id),
                    child: const Text('See all'),
                  ),
          ),
          if (applicants.isEmpty)
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const IconBubble(
                    icon: Icons.hourglass_empty_rounded,
                    color: AppColors.tintBlue,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No applicants yet',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: headingColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Share the post or invite people from Find Talent',
                    style: TextStyle(fontSize: 9.5, color: sub),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push(RoutePaths.talentSearch),
                    icon: const Icon(Icons.person_search_rounded, size: 15),
                    label: const Text('Find Talent'),
                  ),
                ],
              ),
            )
          else
            for (final a in applicants.take(3)) ...[
              ApplicantCard(
                applicant: a,
                onTap: () =>
                    context.push(RoutePaths.applicantProfile, extra: a.id),
              ),
              const SizedBox(height: 6),
            ],
          const SectionLabel('About this role'),
          SoftCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              job.description,
              style: TextStyle(fontSize: 10.5, height: 1.5, color: sub),
            ),
          ),
          if (job.responsibilities.isNotEmpty) ...[
            const SectionLabel('Key responsibilities'),
            SoftCard(
              padding: const EdgeInsets.all(12),
              child: TickList(job.responsibilities),
            ),
          ],
          const SectionLabel('Skills required'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in job.skills)
                TintTag(s, color: AppColors.tintBlue, height: 20, fontSize: 9),
            ],
          ),
          if (job.perks.isNotEmpty) ...[
            const SectionLabel('Perks & benefits'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in job.perks)
                  TintTag(
                    p,
                    color: AppColors.tintGreen,
                    icon: Icons.star_rounded,
                    height: 20,
                    fontSize: 9,
                  ),
              ],
            ),
          ],
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
                onPressed: () => context.showSnackBar('Job link copied'),
                child: const Icon(Icons.share_outlined, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: job.status == JobPostStatus.draft
                  ? ElevatedButton.icon(
                      onPressed: () =>
                          context.push(RoutePaths.postJob, extra: job.id),
                      icon: const Icon(Icons.rocket_launch_rounded, size: 15),
                      label: const Text('Finish & Publish'),
                    )
                  : ElevatedButton.icon(
                      onPressed: () =>
                          context.push(RoutePaths.applicants, extra: job.id),
                      icon: const Icon(Icons.people_alt_rounded, size: 15),
                      label: Text('View Applicants (${applicants.length})'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref, JobPost job) {
    final notifier = ref.read(recruitmentProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Manage job post',
        subtitle: job.title,
        children: [
          if (job.status == JobPostStatus.active)
            SheetOption(
              icon: Icons.pause_circle_outline_rounded,
              label: 'Pause hiring',
              onTap: () {
                Navigator.pop(sheetContext);
                context.runApi(
                  () => notifier.setJobStatus(job.id, JobPostStatus.paused),
                  success: 'Job paused · hidden from job seekers',
                );
              },
            ),
          if (job.status == JobPostStatus.paused ||
              job.status == JobPostStatus.closed)
            SheetOption(
              icon: Icons.play_circle_outline_rounded,
              label: 'Re-open job',
              onTap: () {
                Navigator.pop(sheetContext);
                context.runApi(
                  () => notifier.setJobStatus(job.id, JobPostStatus.active),
                  success: 'Job is live again',
                );
              },
            ),
          if (job.status != JobPostStatus.closed &&
              job.status != JobPostStatus.draft)
            SheetOption(
              icon: Icons.lock_outline_rounded,
              label: 'Close job',
              onTap: () {
                Navigator.pop(sheetContext);
                context.runApi(
                  () => notifier.setJobStatus(job.id, JobPostStatus.closed),
                  success: 'Job closed',
                );
              },
            ),
          SheetOption(
            icon: Icons.copy_rounded,
            label: 'Duplicate as draft',
            onTap: () {
              Navigator.pop(sheetContext);
              JobPost? copy;
              context
                  .runApi(
                    () async => copy = await notifier.duplicateJob(job.id),
                  )
                  .then((ok) {
                    if (ok && context.mounted) {
                      context.push(RoutePaths.postJob, extra: copy!.id);
                    }
                  });
            },
          ),
          SheetOption(
            icon: Icons.share_outlined,
            label: 'Share job link',
            onTap: () {
              Navigator.pop(sheetContext);
              context.showSnackBar('Job link copied');
            },
          ),
          SheetOption(
            icon: Icons.delete_outline_rounded,
            label: 'Delete job post',
            destructive: true,
            onTap: () async {
              Navigator.pop(sheetContext);
              final ok = await confirmDialog(
                context,
                title: 'Delete job post?',
                message:
                    '"${job.title}" and its applications will be removed permanently.',
                confirmLabel: 'Delete',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              final deleted = await context.runApi(
                () => notifier.deleteJob(job.id),
                success: 'Job post deleted',
              );
              if (deleted && context.mounted) context.pop();
            },
          ),
        ],
      ),
    );
  }
}
