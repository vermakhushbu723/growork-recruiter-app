import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import '../../data/job_post_model.dart';
import '../../providers/recruitment_provider.dart';
import '../widgets/applicant_card.dart';

/// What to show on the applicants screen: one job or all jobs, optionally
/// pre-filtered to one pipeline stage.
class ApplicantsArgs {
  const ApplicantsArgs({this.jobId, this.status});

  final String? jobId;
  final ApplicantStatus? status;
}

class ApplicantsScreen extends ConsumerStatefulWidget {
  const ApplicantsScreen({super.key, this.args = const ApplicantsArgs()});

  final ApplicantsArgs args;

  @override
  ConsumerState<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends ConsumerState<ApplicantsScreen> {
  late ApplicantStatus? _status = widget.args.status;
  late String? _jobId = widget.args.jobId;
  String _query = '';
  String _sort = 'Best match';

  @override
  Widget build(BuildContext context) {
    final hiring = ref.watch(recruitmentProvider);
    final job = _jobId == null ? null : hiring.job(_jobId!);
    final scope = _jobId == null
        ? hiring.applicants
        : hiring.applicantsFor(_jobId!);
    final q = _query.toLowerCase();
    final list = scope.where((a) {
      if (_status != null && a.status != _status) return false;
      if (q.isEmpty) return true;
      return a.name.toLowerCase().contains(q) ||
          a.headline.toLowerCase().contains(q) ||
          a.skills.any((s) => s.toLowerCase().contains(q));
    }).toList();
    if (_sort == 'Best match') {
      list.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Applicants'),
            Text(
              job?.title ?? 'All job posts',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: context.textSubColor,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 2, 12, 10),
              child: SearchFilterBar(
                height: 35,
                fontSize: 9.5,
                hint: 'Search by name, role or skill...',
                solidFilter: true,
                showFilterDot: _jobId != null && widget.args.jobId == null,
                onChanged: (v) => setState(() => _query = v),
                onFilter: () => _showFilterSheet(context, hiring),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ChipScroller(
              children: [
                PillChip(
                  label: 'All (${scope.length})',
                  selected: _status == null,
                  onTap: () => setState(() => _status = null),
                ),
                for (final s in ApplicantStatus.values)
                  PillChip(
                    label:
                        '${s.label} (${scope.where((a) => a.status == s).length})',
                    color: s.color,
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
                '${list.length} candidate${list.length == 1 ? '' : 's'}',
                trailing: SortByButton(
                  value: _sort,
                  onTap: () => _showSortSheet(context),
                ),
              ),
            ),
          ),
          if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.person_off_outlined,
                title: 'No applicants here',
                message: 'Try another stage or search term',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 20),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final a = list[i];
                  return ApplicantCard(
                    applicant: a,
                    jobTitle: _jobId == null
                        ? hiring.job(a.jobId)?.title
                        : null,
                    onTap: () =>
                        context.push(RoutePaths.applicantProfile, extra: a.id),
                    onShortlist: () => _toggleShortlist(a),
                    onMessage: () => context.push(
                      RoutePaths.chatRoom,
                      extra: ChatTarget(userId: a.candidateId, name: a.name),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _toggleShortlist(Applicant a) {
    final notifier = ref.read(recruitmentProvider.notifier);
    final on = a.status != ApplicantStatus.shortlisted;
    context.runApi(
      () => notifier.setApplicantStatus(
        a.id,
        on ? ApplicantStatus.shortlisted : ApplicantStatus.applied,
      ),
      success: on
          ? '${a.name} shortlisted'
          : '${a.name} removed from shortlist',
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Sort applicants by',
        children: [
          for (final o in const [
            (Icons.auto_awesome_outlined, 'Best match'),
            (Icons.schedule_rounded, 'Newest'),
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

  void _showFilterSheet(BuildContext context, RecruitmentState hiring) {
    if (widget.args.jobId != null) {
      context.showSnackBar('Showing applicants for this job only');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
        child: SheetBody(
          title: 'Filter by job post',
          children: [
            SheetOption(
              icon: Icons.all_inclusive_rounded,
              label: 'All job posts',
              selected: _jobId == null,
              onTap: () {
                setState(() => _jobId = null);
                Navigator.pop(sheetContext);
              },
            ),
            for (final j in hiring.jobs.where(
              (j) => hiring.applicantsFor(j.id).isNotEmpty,
            ))
              SheetOption(
                icon: Icons.work_outline_rounded,
                label: '${j.title} (${hiring.applicantsFor(j.id).length})',
                selected: _jobId == j.id,
                onTap: () {
                  setState(() => _jobId = j.id);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }
}
