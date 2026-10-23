import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../chat/presentation/screens/call_screen.dart';
import '../../data/job_post_model.dart';
import '../../providers/recruitment_provider.dart';
import '../widgets/applicant_card.dart';

class ApplicantProfileScreen extends ConsumerStatefulWidget {
  const ApplicantProfileScreen({super.key, required this.applicantId});

  final String applicantId;

  @override
  ConsumerState<ApplicantProfileScreen> createState() =>
      _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState
    extends ConsumerState<ApplicantProfileScreen> {
  late final _note = TextEditingController(
    text: ref.read(recruitmentProvider).applicant(widget.applicantId)?.note,
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _move(Applicant a, ApplicantStatus status, String message) {
    context.runApi(
      () => ref
          .read(recruitmentProvider.notifier)
          .setApplicantStatus(a.id, status),
      success: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hiring = ref.watch(recruitmentProvider);
    final a = hiring.applicant(widget.applicantId);
    if (a == null) {
      if (!hiring.loaded) return const LoadingView();
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Candidate not found',
        ),
      );
    }
    final job = hiring.job(a.jobId);
    final interviews = hiring.interviews
        .where((i) => i.applicantId == a.id)
        .toList();
    final sub = context.textSubColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Profile'),
        actions: [
          IconButton(
            tooltip: 'Call',
            icon: Icon(Icons.call_outlined, color: context.accentColor),
            onPressed: () =>
                context.push(RoutePaths.call, extra: CallArgs(name: a.name)),
          ),
          IconButton(
            tooltip: 'Message',
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: context.accentColor,
            ),
            onPressed: () => context.push(
              RoutePaths.chatRoom,
              extra: ChatTarget(userId: a.candidateId, name: a.name),
            ),
          ),
          IconButton(
            tooltip: 'Move to stage',
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showStageSheet(context, a),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          _Hero(applicant: a),
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
                label: 'Experience',
                value: a.experience,
                icon: Icons.work_outline_rounded,
                color: AppColors.tintBlue,
              ),
              StatBox(
                label: 'Expected',
                value: a.expectedSalary,
                icon: Icons.payments_outlined,
                color: AppColors.tintGreen,
              ),
              StatBox(
                label: 'Notice period',
                value: a.noticePeriod,
                icon: Icons.timer_outlined,
                color: AppColors.tintOrange,
              ),
              StatBox(
                label: 'Current company',
                value: a.currentCompany ?? '—',
                icon: Icons.apartment_rounded,
                color: AppColors.tintPurple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: matchColor(
                a.matchScore,
              ).withValues(alpha: context.isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: matchColor(a.matchScore).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                IconBubble(
                  icon: Icons.auto_awesome_rounded,
                  color: matchColor(a.matchScore),
                  size: 34,
                  iconSize: 17,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Resume Match · ${a.matchScore}%',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: headingColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job == null
                            ? 'Based on the job requirements'
                            : 'Matches ${a.skills.where(job.skills.contains).length} of ${job.skills.length} required skills for ${job.title}',
                        style: TextStyle(fontSize: 9.5, color: sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (job != null) ...[
            const SectionLabel('Applied for'),
            MenuTile(
              icon: Icons.work_outline_rounded,
              title: job.title,
              subtitle:
                  '${job.type} · ${job.workMode} · Applied ${a.appliedAgo}',
              onTap: () => context.push(RoutePaths.jobDetails, extra: job.id),
            ),
          ],
          const SectionLabel('Cover letter'),
          SoftCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              a.coverLetter,
              style: TextStyle(fontSize: 10.5, height: 1.5, color: sub),
            ),
          ),
          const SectionLabel('Skills'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in a.skills)
                TintTag(
                  s,
                  color: job?.skills.contains(s) == true
                      ? AppColors.tintGreen
                      : AppColors.tintBlue,
                  icon: job?.skills.contains(s) == true
                      ? Icons.check_rounded
                      : null,
                  height: 20,
                  fontSize: 9,
                ),
            ],
          ),
          const SectionLabel('Resume & contact'),
          MenuTile(
            icon: Icons.picture_as_pdf_rounded,
            color: AppColors.tintRed,
            title: a.resumeName,
            subtitle: 'Tap to view · PDF',
            onTap: () => context.showSnackBar('Opening ${a.resumeName}'),
            trailing: Icon(
              Icons.download_rounded,
              size: 17,
              color: context.accentColor,
            ),
          ),
          const SizedBox(height: 6),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                InfoRow(
                  label: 'Email',
                  value: a.email,
                  icon: Icons.mail_outline_rounded,
                ),
                InfoRow(
                  label: 'Phone',
                  value: a.phone,
                  icon: Icons.phone_outlined,
                ),
                InfoRow(
                  label: 'Education',
                  value: a.education,
                  icon: Icons.school_outlined,
                ),
                InfoRow(
                  label: 'Location',
                  value: a.location,
                  icon: Icons.location_on_outlined,
                ),
              ],
            ),
          ),
          if (interviews.isNotEmpty) ...[
            const SectionLabel('Interviews'),
            for (final i in interviews) ...[
              MenuTile(
                icon: i.mode.icon,
                color: i.status.color,
                title: '${i.round} · ${i.status.label}',
                subtitle: DateFormat(
                  'EEE, d MMM yyyy · h:mm a',
                ).format(i.dateTime),
                onTap: () => context.push(RoutePaths.interviews),
              ),
              const SizedBox(height: 6),
            ],
          ],
          const SectionLabel('Private note'),
          TextField(
            controller: _note,
            maxLines: 3,
            style: TextStyle(fontSize: 11, color: context.textMainColor),
            decoration: InputDecoration(
              hintText: 'Only your team can see this note',
              suffixIcon: IconButton(
                icon: Icon(Icons.save_outlined, color: context.accentColor),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  context.runApi(
                    () => ref
                        .read(recruitmentProvider.notifier)
                        .saveNote(a.id, _note.text.trim()),
                    success: 'Note saved',
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(child: _actions(context, a)),
    );
  }

  Widget _actions(BuildContext context, Applicant a) {
    Widget reject() => SizedBox(
      width: 96,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        onPressed: () async {
          final ok = await confirmDialog(
            context,
            title: 'Reject ${a.name}?',
            message: 'They will be notified that the role has moved forward.',
            confirmLabel: 'Reject',
            destructive: true,
          );
          if (ok) _move(a, ApplicantStatus.rejected, '${a.name} rejected');
        },
        child: const Text('Reject'),
      ),
    );

    Widget primary(String label, IconData icon, VoidCallback onTap) => Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
      ),
    );

    return switch (a.status) {
      ApplicantStatus.applied => Row(
        children: [
          reject(),
          const SizedBox(width: 10),
          primary(
            'Shortlist',
            Icons.star_rounded,
            () =>
                _move(a, ApplicantStatus.shortlisted, '${a.name} shortlisted'),
          ),
        ],
      ),
      ApplicantStatus.shortlisted => Row(
        children: [
          reject(),
          const SizedBox(width: 10),
          primary(
            'Schedule Interview',
            Icons.event_rounded,
            () => context.push(RoutePaths.scheduleInterview, extra: a.id),
          ),
        ],
      ),
      ApplicantStatus.interview => Row(
        children: [
          reject(),
          const SizedBox(width: 10),
          primary(
            'Send Offer',
            Icons.local_offer_rounded,
            () => context.push(RoutePaths.sendOffer, extra: a.id),
          ),
        ],
      ),
      ApplicantStatus.offered => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push(RoutePaths.sendOffer, extra: a.id),
              child: const Text('Revise Offer'),
            ),
          ),
          const SizedBox(width: 10),
          primary(
            'Mark as Hired',
            Icons.verified_rounded,
            () => _move(a, ApplicantStatus.hired, '🎉 ${a.name} hired!'),
          ),
        ],
      ),
      ApplicantStatus.hired => ElevatedButton.icon(
        onPressed: () => context.push(
          RoutePaths.chatRoom,
          extra: ChatTarget(userId: a.candidateId, name: a.name),
        ),
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
        label: const Text('Message New Hire'),
      ),
      ApplicantStatus.rejected => OutlinedButton.icon(
        onPressed: () =>
            _move(a, ApplicantStatus.applied, '${a.name} moved back to New'),
        icon: const Icon(Icons.undo_rounded, size: 15),
        label: const Text('Reconsider Candidate'),
      ),
    };
  }

  void _showStageSheet(BuildContext context, Applicant a) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Move to stage',
        subtitle: a.name,
        children: [
          for (final s in ApplicantStatus.values)
            SheetOption(
              icon: s.icon,
              label: s.label,
              selected: a.status == s,
              destructive: s == ApplicantStatus.rejected,
              onTap: () {
                Navigator.pop(sheetContext);
                _move(a, s, '${a.name} moved to ${s.label}');
              },
            ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.applicant});

  final Applicant applicant;

  @override
  Widget build(BuildContext context) {
    final a = applicant;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF05308C), Color(0xFF0B47B8), Color(0xFF0A3A9A)],
        ),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -60,
            child: Container(
              width: 200,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                UserAvatar(
                  name: a.name,
                  size: 70,
                  ringColor: Colors.white,
                  ringWidth: 2.5,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              a.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _HeroChip(a.status.label, solid: true),
                          _HeroChip('${a.matchScore}% match'),
                          _HeroChip(a.experience),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.label, {this.solid = false});

  final String label;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: solid ? Colors.white : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: solid
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: solid ? AppColors.primary : Colors.white,
          fontSize: 8,
          fontWeight: solid ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
