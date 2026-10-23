import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/success_view.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/job_post_model.dart';
import '../../providers/recruitment_provider.dart';

const _rounds = [
  'HR Round',
  'Technical Round',
  'Assignment Review',
  'Portfolio Review',
  'Final Round',
];

class ScheduleInterviewScreen extends ConsumerStatefulWidget {
  const ScheduleInterviewScreen({super.key, required this.applicantId});

  final String applicantId;

  @override
  ConsumerState<ScheduleInterviewScreen> createState() =>
      _ScheduleInterviewScreenState();
}

class _ScheduleInterviewScreenState
    extends ConsumerState<ScheduleInterviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _interviewer = TextEditingController(
    text: ref.read(authProvider).user?.name,
  );
  final _link = TextEditingController();
  final _message = TextEditingController();
  String _round = 'Technical Round';
  InterviewMode _mode = InterviewMode.video;
  String _length = '45 min';
  DateTime _date = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _time = const TimeOfDay(hour: 11, minute: 0);
  bool _busy = false;
  Interview? _scheduled;

  @override
  void dispose() {
    _interviewer.dispose();
    _link.dispose();
    _message.dispose();
    super.dispose();
  }

  String get _linkLabel => switch (_mode) {
    InterviewMode.video => 'Meeting link',
    InterviewMode.phone => 'Phone number to call',
    InterviewMode.inPerson => 'Office address',
  };

  Future<void> _submit(Applicant a, String jobTitle) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    Interview? interview;
    final ok = await context.runApi(() async {
      interview = await ref
          .read(recruitmentProvider.notifier)
          .scheduleInterview(
            applicantId: a.id,
            dateTime: DateTime(
              _date.year,
              _date.month,
              _date.day,
              _time.hour,
              _time.minute,
            ),
            mode: _mode,
            round: _round,
            durationMins: int.parse(_length.split(' ').first),
            interviewer: _interviewer.text.trim(),
            link: _link.text.trim(),
            message: _message.text.trim(),
          );
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _scheduled = interview;
    });
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
    final jobTitle = hiring.job(a.jobId)?.title ?? 'Role';

    final done = _scheduled;
    if (done != null) {
      return SuccessView(
        icon: Icons.event_available_rounded,
        color: AppColors.tintPurple,
        title: 'Interview Scheduled!',
        message:
            '${a.name} has been invited and will get a calendar invite with the details.',
        details: SoftCard(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              InfoRow(label: 'Round', value: done.round),
              InfoRow(
                label: 'When',
                value: DateFormat('EEE, d MMM · h:mm a').format(done.dateTime),
              ),
              InfoRow(label: 'Mode', value: done.mode.label),
              InfoRow(label: 'Interviewer', value: done.interviewer),
            ],
          ),
        ),
        primaryLabel: 'View All Interviews',
        onPrimary: () => context.pushReplacement(RoutePaths.interviews),
        secondaryLabel: 'Back to Candidate',
        onSecondary: () => context.pop(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Interview')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
          children: [
            SoftCard(
              padding: const EdgeInsets.all(11),
              child: Row(
                children: [
                  UserAvatar(name: a.name, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: headingColor(context),
                          ),
                        ),
                        Text(
                          'For $jobTitle',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: context.textSubColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ChipGroup(
              label: 'Interview round',
              options: _rounds,
              value: _round,
              onChanged: (v) => setState(() => _round = v),
            ),
            const SizedBox(height: 14),
            const FieldLabel('Interview mode'),
            Row(
              children: [
                for (final (i, m) in InterviewMode.values.indexed) ...[
                  if (i > 0) const SizedBox(width: 7),
                  Expanded(
                    child: _ModeTile(
                      mode: m,
                      selected: _mode == m,
                      onTap: () => setState(() {
                        _mode = m;
                        _link.text = switch (m) {
                          InterviewMode.video => '',
                          InterviewMode.phone => a.phone,
                          InterviewMode.inPerson =>
                            ref.read(authProvider).user?.company.location ?? '',
                        };
                      }),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            const FieldLabel('Date & time'),
            Row(
              children: [
                Expanded(
                  child: MenuTile(
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.tintBlue,
                    title: DateFormat('d MMM yyyy').format(_date),
                    subtitle: DateFormat('EEEE').format(_date),
                    trailing: const SizedBox.shrink(),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: MenuTile(
                    icon: Icons.schedule_rounded,
                    color: AppColors.tintPurple,
                    title: _time.format(context),
                    subtitle: 'IST',
                    trailing: const SizedBox.shrink(),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ChipGroup(
              label: 'Duration',
              options: const ['30 min', '45 min', '60 min', '90 min'],
              value: _length,
              onChanged: (v) => setState(() => _length = v),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Interviewer',
              controller: _interviewer,
              icon: Icons.person_outline_rounded,
              validator: (v) => Validators.required(v, field: 'Interviewer'),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: _linkLabel,
              hint: _mode == InterviewMode.video
                  ? 'Paste a Google Meet or Zoom link'
                  : null,
              controller: _link,
              icon: _mode.icon,
              validator: (v) => Validators.required(v, field: _linkLabel),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Message to candidate (optional)',
              hint: 'e.g. Please keep your portfolio ready to share.',
              controller: _message,
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: 'Send Interview Invite',
          icon: Icons.send_rounded,
          loading: _busy,
          onPressed: () => _submit(a, jobTitle),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final InterviewMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.tagBgColor : context.surfaceColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? context.accentColor : context.borderColor,
            width: selected ? 1.6 : 1.1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              mode.icon,
              size: 19,
              color: selected ? context.accentColor : context.textSubColor,
            ),
            const SizedBox(height: 4),
            Text(
              mode.label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: selected ? context.accentColor : headingColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
