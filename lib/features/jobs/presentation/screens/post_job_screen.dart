import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/success_view.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../wallet/providers/wallet_provider.dart';
import '../../data/job_post_model.dart';
import '../../providers/recruitment_provider.dart';
import '../widgets/job_post_card.dart';

const _steps = [
  'Job basics',
  'Description & skills',
  'Salary & perks',
  'Review & publish',
];

const _skillSuggestions = {
  'Engineering': [
    'Flutter',
    'React',
    'Node.js',
    'Java',
    'Python',
    'AWS',
    'SQL',
    'Git',
  ],
  'Design': [
    'Figma',
    'Prototyping',
    'User Research',
    'Illustrator',
    'Design Systems',
  ],
  'Marketing': ['SEO', 'Social Media', 'Content', 'Google Ads', 'Canva'],
  'Sales': ['B2B Sales', 'CRM', 'Negotiation', 'Lead Generation'],
  'Operations': ['Excel', 'Process Design', 'Vendor Management'],
  'Data & Analytics': ['SQL', 'Python', 'Power BI', 'Excel', 'Statistics'],
  'Customer Support': ['Communication', 'Zendesk', 'Hindi', 'English'],
  'HR & Admin': ['Recruitment', 'Payroll', 'Onboarding', 'MS Office'],
};

/// Multi-step form to post a new job / internship, or edit an existing one
/// when [jobId] is given.
class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key, this.jobId});

  final String? jobId;

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());
  late final JobPost? _editing = widget.jobId == null
      ? null
      : ref.read(recruitmentProvider).job(widget.jobId!);

  int _step = 0;
  bool _busy = false;
  JobPost? _published;

  late final _title = TextEditingController(text: _editing?.title);
  late final _location = TextEditingController(text: _editing?.location);
  late final _description = TextEditingController(text: _editing?.description);
  late final _responsibilities = TextEditingController(
    text: _editing?.responsibilities.join('\n'),
  );
  late final _salaryMin = TextEditingController(
    text: _editing == null ? '' : _num(_editing.salaryMin),
  );
  late final _salaryMax = TextEditingController(
    text: _editing == null ? '' : _num(_editing.salaryMax),
  );

  late String _category = _editing?.category ?? jobCategories.first;
  late String _type = _editing?.type ?? 'Full-time';
  late String _workMode = _editing?.workMode ?? 'On-site';
  late int _openings = _editing?.openings ?? 1;
  late List<String> _skills = [...?_editing?.skills];
  late String _experience = _editing?.experience ?? '1–3 yrs';
  late String _level = _editing?.level ?? 'Junior Level';
  late String _duration = _editing?.duration ?? '3 months';
  late Set<String> _perks = {...?_editing?.perks};
  late bool _urgent = _editing?.isUrgent ?? false;
  late DateTime _deadline = DateTime.now().add(const Duration(days: 30));

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  bool get _isInternship => _type == 'Internship';

  @override
  void dispose() {
    for (final c in [
      _title,
      _location,
      _description,
      _responsibilities,
      _salaryMin,
      _salaryMax,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  JobPost _build(JobPostStatus status) {
    final base = JobPost(
      id: _editing?.id ?? '',
      title: _title.text.trim(),
      category: _category,
      type: _type,
      workMode: _workMode,
      location: _workMode == 'Remote' && _location.text.trim().isEmpty
          ? 'Remote'
          : _location.text.trim(),
      salaryMin: double.tryParse(_salaryMin.text) ?? 0,
      salaryMax: double.tryParse(_salaryMax.text) ?? 0,
      experience: _isInternship ? '0–1 yrs' : _experience,
      level: _isInternship ? 'Fresher' : _level,
      openings: _openings,
      skills: _skills,
      description: _description.text.trim(),
      responsibilities: _responsibilities.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList(),
      perks: _perks.toList(),
      status: status,
      postedAgo: status == JobPostStatus.draft
          ? 'Not posted'
          : (_editing?.postedAgo ?? 'Just now'),
      deadline: DateFormat('d MMM yyyy').format(_deadline),
      views: _editing?.views ?? 0,
      isUrgent: _urgent,
      duration: _isInternship ? _duration : null,
    );
    return base;
  }

  void _next() {
    if (_step < 3) {
      if (!_formKeys[_step].currentState!.validate()) return;
      if (_step == 1 && _skills.isEmpty) {
        context.showSnackBar('Add at least one skill', isError: true);
        return;
      }
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _saveDraft() async {
    if (_title.text.trim().isEmpty) {
      context.showSnackBar('Add a job title to save a draft', isError: true);
      setState(() => _step = 0);
      return;
    }
    final ok = await context.runApi(
      () => ref
          .read(recruitmentProvider.notifier)
          .saveJob(_build(JobPostStatus.draft)),
    );
    if (!ok || !mounted) return;
    context.pop();
    context.showSnackBar('Saved to drafts');
  }

  Future<void> _publish() async {
    setState(() => _busy = true);
    final job = _build(
      _editing != null && _editing.status != JobPostStatus.draft
          ? _editing.status
          : JobPostStatus.active,
    );
    try {
      final saved = await ref.read(recruitmentProvider.notifier).saveJob(job);
      // Publishing used a credit on the server.
      ref.read(walletProvider.notifier).load();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _published = saved;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.status == 402) {
        final buy = await confirmDialog(
          context,
          title: 'No job credits left',
          message: 'Buy a hiring plan to publish more jobs this month.',
          confirmLabel: 'View Plans',
        );
        if (buy && mounted) context.push(RoutePaths.plans);
      } else {
        context.showSnackBar(e.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final published = _published;
    if (published != null) {
      final editing =
          _editing != null && _editing.status != JobPostStatus.draft;
      return SuccessView(
        title: editing ? 'Job Updated!' : 'Job Posted!',
        message: editing
            ? 'Your changes to ${published.title} are live.'
            : '${published.title} is now live. Matching job seekers will be notified and applications will show up in your Jobs tab.',
        primaryLabel: 'View Job Post',
        onPrimary: () =>
            context.pushReplacement(RoutePaths.jobDetails, extra: published.id),
        secondaryLabel: 'Back to My Jobs',
        onSecondary: () => context.go(RoutePaths.jobs),
      );
    }

    final credits = ref.watch(walletProvider).jobCredits;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing == null ? 'Post a Job' : 'Edit Job'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _back,
          ),
          actions: [
            TextButton(onPressed: _saveDraft, child: const Text('Save draft')),
            const SizedBox(width: 6),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 2, 13, 8),
              child: StepProgress(step: _step, steps: _steps),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    0 => _basics(),
                    1 => _details(),
                    2 => _salary(),
                    _ => _review(credits),
                  },
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomActionBar(
          child: Row(
            children: [
              if (_step > 0) ...[
                SizedBox(
                  width: 96,
                  child: OutlinedButton(
                    onPressed: _back,
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _step < 3
                    ? ElevatedButton(
                        onPressed: _next,
                        child: const Text('Continue'),
                      )
                    : LoadingButton(
                        label:
                            _editing == null ||
                                _editing.status == JobPostStatus.draft
                            ? 'Publish Job'
                            : 'Save Changes',
                        icon: Icons.rocket_launch_rounded,
                        loading: _busy,
                        onPressed: _publish,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scroll(int formIndex, List<Widget> children) => Form(
    key: formIndex < 3 ? _formKeys[formIndex] : null,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
      children: children,
    ),
  );

  Widget _basics() => _scroll(0, [
    LabeledField(
      label: 'Job title',
      hint: 'e.g. Flutter Developer',
      controller: _title,
      icon: Icons.work_outline_rounded,
      validator: (v) => Validators.required(v, field: 'Job title'),
    ),
    const SizedBox(height: 12),
    PickerField(
      label: 'Category',
      value: _category,
      options: jobCategories,
      icon: Icons.category_outlined,
      onChanged: (v) => setState(() => _category = v),
    ),
    const SizedBox(height: 14),
    ChipGroup(
      label: 'Job type',
      options: jobPostTypes,
      value: _type,
      required: true,
      onChanged: (v) => setState(() => _type = v),
    ),
    const SizedBox(height: 14),
    ChipGroup(
      label: 'Work mode',
      options: workModes,
      value: _workMode,
      required: true,
      onChanged: (v) => setState(() => _workMode = v),
    ),
    const SizedBox(height: 14),
    LabeledField(
      label: _workMode == 'Remote' ? 'Location (optional)' : 'Office location',
      hint: _workMode == 'Remote' ? 'Remote' : 'e.g. Noida, India',
      controller: _location,
      icon: Icons.location_on_outlined,
      validator: (v) => _workMode == 'Remote'
          ? null
          : Validators.required(v, field: 'Location'),
    ),
    const SizedBox(height: 14),
    const FieldLabel('Number of openings'),
    SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      child: Row(
        children: [
          const IconBubble(
            icon: Icons.groups_outlined,
            color: AppColors.tintBlue,
            size: 30,
            iconSize: 15,
            circle: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_openings position${_openings == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: headingColor(context),
              ),
            ),
          ),
          IconButton(
            onPressed: _openings > 1 ? () => setState(() => _openings--) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
          ),
          IconButton(
            onPressed: () => setState(() => _openings++),
            icon: Icon(
              Icons.add_circle_rounded,
              size: 20,
              color: context.accentColor,
            ),
          ),
        ],
      ),
    ),
  ]);

  Widget _details() => _scroll(1, [
    LabeledField(
      label: 'Job description',
      hint: 'What will this person do? What makes the role exciting?',
      controller: _description,
      maxLines: 6,
      validator: (v) => (v == null || v.trim().length < 30)
          ? 'Write at least 30 characters'
          : null,
    ),
    const SizedBox(height: 12),
    LabeledField(
      label: 'Key responsibilities (one per line)',
      hint: 'Build and ship features\nWrite tests\nReview code',
      controller: _responsibilities,
      maxLines: 5,
    ),
    const SizedBox(height: 14),
    SkillsInput(
      skills: _skills,
      suggestions: _skillSuggestions[_category] ?? const [],
      onChanged: (v) => setState(() => _skills = v),
    ),
  ]);

  Widget _salary() => _scroll(2, [
    FieldLabel(
      _isInternship ? 'Monthly stipend (₹ thousands)' : 'Annual CTC (₹ lakhs)',
      required: true,
    ),
    Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _salaryMin,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 11, color: context.textMainColor),
            decoration: InputDecoration(
              hintText: _isInternship ? 'Min e.g. 10' : 'Min e.g. 6',
              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 16),
            ),
            validator: (v) =>
                (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter minimum' : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('to', style: TextStyle(color: context.textSubColor)),
        ),
        Expanded(
          child: TextFormField(
            controller: _salaryMax,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 11, color: context.textMainColor),
            decoration: InputDecoration(
              hintText: _isInternship ? 'Max e.g. 20' : 'Max e.g. 12',
              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 16),
            ),
            validator: (v) {
              final max = double.tryParse(v ?? '') ?? 0;
              final min = double.tryParse(_salaryMin.text) ?? 0;
              if (max <= 0) return 'Enter maximum';
              if (max < min) return 'Must be ≥ minimum';
              return null;
            },
          ),
        ),
      ],
    ),
    const SizedBox(height: 14),
    if (_isInternship)
      ChipGroup(
        label: 'Internship duration',
        options: const ['1 month', '2 months', '3 months', '6 months'],
        value: _duration,
        onChanged: (v) => setState(() => _duration = v),
      )
    else ...[
      PickerField(
        label: 'Experience required',
        value: _experience,
        options: experienceRanges,
        icon: Icons.timeline_rounded,
        onChanged: (v) => setState(() => _experience = v),
      ),
      const SizedBox(height: 14),
      ChipGroup(
        label: 'Seniority level',
        options: experienceLevels,
        value: _level,
        onChanged: (v) => setState(() => _level = v),
      ),
    ],
    const SizedBox(height: 14),
    MultiChipGroup(
      label: 'Perks & benefits',
      options: commonPerks,
      values: _perks,
      onChanged: (v) => setState(() => _perks = v),
    ),
    const SizedBox(height: 14),
    const FieldLabel('Application deadline'),
    MenuTile(
      icon: Icons.event_outlined,
      color: AppColors.tintPurple,
      title: DateFormat('EEEE, d MMM yyyy').format(_deadline),
      subtitle: 'Applications close at midnight',
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _deadline,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 180)),
        );
        if (picked != null) setState(() => _deadline = picked);
      },
    ),
    const SizedBox(height: 6),
    MenuTile(
      icon: Icons.local_fire_department_outlined,
      color: AppColors.urgentTxt,
      title: 'Mark as Urgent Hiring',
      subtitle: 'Shown first to active job seekers',
      onTap: () => setState(() => _urgent = !_urgent),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: _urgent,
          onChanged: (v) => setState(() => _urgent = v),
        ),
      ),
    ),
  ]);

  Widget _review(int credits) {
    final job = _build(JobPostStatus.active);
    final company = ref.read(authProvider).user?.company.name ?? 'Company';
    final usesCredit =
        _editing == null || _editing.status == JobPostStatus.draft;
    return ListView(
      padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
      children: [
        Text(
          'This is how job seekers will see your post',
          style: TextStyle(fontSize: 10, color: context.textSubColor),
        ),
        const SizedBox(height: 8),
        JobPostCard(
          job: job,
          company: company,
          applicants: 0,
          newApplicants: 0,
          onTap: () {},
        ),
        const SectionLabel('Summary'),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              InfoRow(label: 'Category', value: job.category),
              InfoRow(
                label: 'Type · Mode',
                value: '${job.type} · ${job.workMode}',
              ),
              InfoRow(label: 'Location', value: job.location),
              InfoRow(
                label: job.isInternship ? 'Stipend' : 'Salary',
                value: job.salaryLabel,
                valueColor: context.accentColor,
              ),
              if (job.isInternship)
                InfoRow(label: 'Duration', value: job.duration ?? '')
              else
                InfoRow(
                  label: 'Experience',
                  value: '${job.experience} · ${job.level}',
                ),
              InfoRow(label: 'Openings', value: '${job.openings}'),
              InfoRow(label: 'Deadline', value: job.deadline),
              InfoRow(label: 'Skills', value: job.skills.join(', ')),
              if (job.perks.isNotEmpty)
                InfoRow(label: 'Perks', value: job.perks.join(', ')),
            ],
          ),
        ),
        const SectionLabel('Description'),
        SoftCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.description,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.5,
                  color: context.textSubColor,
                ),
              ),
              if (job.responsibilities.isNotEmpty) ...[
                const SizedBox(height: 8),
                TickList(job.responsibilities),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (usesCredit)
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.tintBlue.withValues(
                alpha: context.isDark ? 0.15 : 0.07,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  size: 16,
                  color: AppColors.tintBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Publishing uses 1 job credit · $credits left on your plan',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: headingColor(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(RoutePaths.plans),
                  child: const Text('Plans'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
