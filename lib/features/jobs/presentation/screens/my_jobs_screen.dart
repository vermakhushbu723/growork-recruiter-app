import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/banners.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/job_post_model.dart';
import '../../providers/recruitment_provider.dart';
import '../widgets/job_post_card.dart';

/// Jobs tab: every job & internship the recruiter posted, with the hiring
/// pipeline at a glance.
class MyJobsScreen extends ConsumerStatefulWidget {
  const MyJobsScreen({super.key});

  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen> {
  String _query = '';
  JobPostStatus? _status;
  String? _type;
  String _sort = 'Latest';

  @override
  Widget build(BuildContext context) {
    final hiring = ref.watch(recruitmentProvider);
    final company = ref.watch(authProvider).user?.company.name ?? 'Company';

    final jobs = hiring.jobs.where((j) {
      if (_status != null && j.status != _status) return false;
      if (_type != null && j.type != _type) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return j.title.toLowerCase().contains(q) ||
          j.category.toLowerCase().contains(q) ||
          j.skills.any((s) => s.toLowerCase().contains(q));
    }).toList();
    if (_sort == 'Most applicants') {
      jobs.sort(
        (a, b) => hiring
            .applicantsFor(b.id)
            .length
            .compareTo(hiring.applicantsFor(a.id).length),
      );
    } else if (_sort == 'Most views') {
      jobs.sort((a, b) => b.views.compareTo(a.views));
    }

    int count(ApplicantStatus s) =>
        hiring.applicants.where((a) => a.status == s).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'post_job_fab',
        onPressed: () => context.push(RoutePaths.postJob),
        backgroundColor: kButtonBlue,
        foregroundColor: Colors.white,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(
          'Post Job',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 14, 0),
                child: PageHeader(
                  title: 'My Job Posts',
                  titleSize: 18.5,
                  onBack: () => context.go(RoutePaths.home),
                  subtitleWidget: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${hiring.activeJobs.length} active',
                          style: GoogleFonts.inter(
                            color: context.accentColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' · ${hiring.applicants.length} total applicants',
                        ),
                      ],
                    ),
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: context.textSubColor,
                    ),
                  ),
                  trailing: HeaderActionButton(
                    icon: Icons.event_note_outlined,
                    label: 'Interviews',
                    onTap: () => context.push(RoutePaths.interviews),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 12, 10),
                child: SearchFilterBar(
                  height: 35,
                  fontSize: 9,
                  hint: 'Search your jobs by title, skill or category...',
                  solidFilter: true,
                  showFilterDot: _type != null,
                  onChanged: (v) => setState(() => _query = v),
                  onFilter: () => _showTypeSheet(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 0, 13, 10),
                child: PipelineStrip(
                  items: [
                    for (final s in const [
                      ApplicantStatus.applied,
                      ApplicantStatus.shortlisted,
                      ApplicantStatus.interview,
                      ApplicantStatus.offered,
                      ApplicantStatus.hired,
                    ])
                      (
                        label: s.label,
                        count: count(s),
                        color: s.color,
                        onTap: () =>
                            context.push(RoutePaths.applicants, extra: s),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ChipScroller(
                children: [
                  PillChip(
                    label: 'All (${hiring.jobs.length})',
                    selected: _status == null,
                    onTap: () => setState(() => _status = null),
                  ),
                  for (final s in JobPostStatus.values)
                    PillChip(
                      label:
                          '${s.label} (${hiring.jobs.where((j) => j.status == s).length})',
                      selected: _status == s,
                      onTap: () => setState(() => _status = s),
                    ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 10, 10, 6),
                child: SectionTitle(
                  _type == null ? 'All Postings' : '$_type Postings',
                  trailing: SortByButton(
                    value: _sort,
                    onTap: () => _showSortSheet(context),
                  ),
                ),
              ),
            ),
            if (jobs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.work_off_outlined,
                  title: 'No job posts here',
                  message:
                      'Post a job or internship to start receiving applicants',
                  actionLabel: 'Post a Job',
                  onAction: () => context.push(RoutePaths.postJob),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(13, 0, 13, 80),
                sliver: SliverList.separated(
                  itemCount: jobs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return JobPostCard(
                      job: job,
                      company: company,
                      applicants: hiring.applicantsFor(job.id).length,
                      newApplicants: hiring.countFor(
                        job.id,
                        ApplicantStatus.applied,
                      ),
                      onTap: () =>
                          context.push(RoutePaths.jobDetails, extra: job.id),
                      onApplicants: () =>
                          context.push(RoutePaths.applicants, extra: job.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Sort job posts by',
        children: [
          for (final o in const [
            (Icons.schedule_rounded, 'Latest'),
            (Icons.people_outline_rounded, 'Most applicants'),
            (Icons.visibility_outlined, 'Most views'),
          ])
            SheetOption(
              icon: o.$1,
              label: o.$2,
              selected: _sort == o.$2,
              onTap: () {
                setState(() => _sort = o.$2);
                Navigator.pop(sheetContext);
              },
            ),
        ],
      ),
    );
  }

  void _showTypeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Filter by job type',
        children: [
          SheetOption(
            icon: Icons.all_inclusive_rounded,
            label: 'All types',
            selected: _type == null,
            onTap: () {
              setState(() => _type = null);
              Navigator.pop(sheetContext);
            },
          ),
          for (final t in jobPostTypes)
            SheetOption(
              icon: t == 'Internship'
                  ? Icons.school_outlined
                  : Icons.work_outline_rounded,
              label: t,
              selected: _type == t,
              onTap: () {
                setState(() => _type = t);
                Navigator.pop(sheetContext);
              },
            ),
        ],
      ),
    );
  }
}
