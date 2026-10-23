import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/success_view.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/project_models.dart';
import '../../providers/client_projects_provider.dart';
import '../widgets/project_post_card.dart';

const _steps = ['Project details', 'Budget & timeline', 'Review & post'];

const _skillSuggestions = {
  'Web Development': [
    'React',
    'Next.js',
    'TypeScript',
    'Tailwind CSS',
    'WordPress',
  ],
  'Design': ['Figma', 'Logo Design', 'Branding', 'Illustrator', 'UI Design'],
  'Mobile Development': [
    'Flutter',
    'React Native',
    'Kotlin',
    'Swift',
    'Firebase',
  ],
  'Content Writing': ['SEO', 'Copywriting', 'Blog Writing', 'Research'],
  'Digital Marketing': ['Google Ads', 'Meta Ads', 'SEO', 'Email Marketing'],
  'Backend Development': ['Node.js', 'Python', 'MongoDB', 'PostgreSQL', 'AWS'],
};

const _levelHints = {
  'Entry': 'New freelancers · lowest rates',
  'Intermediate': 'Good experience · fair rates',
  'Expert': 'Top specialists · premium rates',
};

/// Multi-step form to post a freelance project, or edit one ([projectId]).
class PostProjectScreen extends ConsumerStatefulWidget {
  const PostProjectScreen({super.key, this.projectId});

  final String? projectId;

  @override
  ConsumerState<PostProjectScreen> createState() => _PostProjectScreenState();
}

class _PostProjectScreenState extends ConsumerState<PostProjectScreen> {
  final _formKeys = List.generate(2, (_) => GlobalKey<FormState>());
  late final ProjectPost? _editing = widget.projectId == null
      ? null
      : ref.read(clientProjectsProvider).project(widget.projectId!);

  int _step = 0;
  bool _busy = false;
  ProjectPost? _posted;

  late final _title = TextEditingController(text: _editing?.title);
  late final _description = TextEditingController(text: _editing?.description);
  late final _budgetMin = TextEditingController(
    text: _editing == null ? '' : '${_editing.budgetMin}',
  );
  late final _budgetMax = TextEditingController(
    text: _editing == null ? '' : '${_editing.budgetMax}',
  );
  late String _category =
      _editing?.category ?? projectCategories.first.category;
  late List<String> _skills = [...?_editing?.skills];
  late List<String> _attachments = [...?_editing?.attachments];
  late PricingType _pricing = _editing?.pricing ?? PricingType.fixed;
  late String _duration = _editing?.duration ?? '1–2 weeks';
  late String _level = _editing?.level ?? 'Intermediate';
  String _visibility = 'Public';

  bool get _isFixed => _pricing == PricingType.fixed;

  @override
  void dispose() {
    for (final c in [_title, _description, _budgetMin, _budgetMax]) {
      c.dispose();
    }
    super.dispose();
  }

  ProjectPost _build(ProjectStatus status) => ProjectPost(
    id: _editing?.id ?? '',
    title: _title.text.trim(),
    category: _category,
    description: _description.text.trim(),
    skills: _skills,
    pricing: _pricing,
    budgetMin: int.tryParse(_budgetMin.text) ?? 0,
    budgetMax: int.tryParse(_budgetMax.text) ?? 0,
    duration: _duration,
    level: _level,
    status: status,
    postedAgo: status == ProjectStatus.draft
        ? 'Not posted'
        : (_editing?.postedAgo == 'Not posted'
              ? 'Just now'
              : (_editing?.postedAgo ?? 'Just now')),
    views: _editing?.views ?? 0,
    attachments: _attachments,
    hiredFreelancer: _editing?.hiredFreelancer,
  );

  void _next() {
    if (!_formKeys[_step].currentState!.validate()) return;
    if (_step == 0 && _skills.isEmpty) {
      context.showSnackBar('Add at least one skill', isError: true);
      return;
    }
    setState(() => _step++);
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
      context.showSnackBar(
        'Add a project title to save a draft',
        isError: true,
      );
      setState(() => _step = 0);
      return;
    }
    final ok = await context.runApi(
      () => ref
          .read(clientProjectsProvider.notifier)
          .saveProject(_build(ProjectStatus.draft), visibility: _visibility),
    );
    if (!ok || !mounted) return;
    context.pop();
    context.showSnackBar('Saved to drafts');
  }

  Future<void> _post() async {
    setState(() => _busy = true);
    final keepStatus =
        _editing != null && _editing.status != ProjectStatus.draft;
    final project = _build(keepStatus ? _editing.status : ProjectStatus.open);
    ProjectPost? saved;
    final ok = await context.runApi(() async {
      saved = await ref
          .read(clientProjectsProvider.notifier)
          .saveProject(project, visibility: _visibility);
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _posted = saved;
    });
  }

  @override
  Widget build(BuildContext context) {
    final posted = _posted;
    if (posted != null) {
      final updated =
          _editing != null && _editing.status != ProjectStatus.draft;
      return SuccessView(
        title: updated ? 'Project Updated!' : 'Project Posted!',
        message: updated
            ? 'Your changes to ${posted.title} are live.'
            : 'Freelancers with ${posted.skills.take(2).join(' & ')} skills are being notified. Proposals usually start arriving within a few hours.',
        primaryLabel: 'View Project',
        onPrimary: () => context.pushReplacement(
          RoutePaths.projectDetails,
          extra: posted.id,
        ),
        secondaryLabel: 'Invite Freelancers',
        onSecondary: () => context.pushReplacement(RoutePaths.talentSearch),
      );
    }

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing == null ? 'Post a Project' : 'Edit Project'),
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
                    0 => _details(),
                    1 => _budget(),
                    _ => _review(),
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
                child: _step < 2
                    ? ElevatedButton(
                        onPressed: _next,
                        child: const Text('Continue'),
                      )
                    : LoadingButton(
                        label:
                            _editing == null ||
                                _editing.status == ProjectStatus.draft
                            ? 'Post Project'
                            : 'Save Changes',
                        icon: Icons.rocket_launch_rounded,
                        loading: _busy,
                        onPressed: _post,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _details() => Form(
    key: _formKeys[0],
    child: ListView(
      padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
      children: [
        LabeledField(
          label: 'Project title',
          hint: 'e.g. Build a React admin dashboard',
          controller: _title,
          icon: Icons.title_rounded,
          validator: (v) => Validators.required(v, field: 'Project title'),
        ),
        const SizedBox(height: 14),
        const FieldLabel('Category', required: true),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in projectCategories)
              PillChip(
                label: c.label,
                height: 25,
                icon: projectCategoryIcon(c.category),
                color: projectCategoryColor(c.category),
                selected: _category == c.category,
                onTap: () => setState(() => _category = c.category),
              ),
          ],
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Describe the project',
          hint:
              'What needs to be done? What will you deliver to the freelancer? What does "done" look like?',
          controller: _description,
          maxLines: 6,
          validator: (v) => (v == null || v.trim().length < 30)
              ? 'Write at least 30 characters'
              : null,
        ),
        const SizedBox(height: 14),
        SkillsInput(
          skills: _skills,
          suggestions: _skillSuggestions[_category] ?? const [],
          onChanged: (v) => setState(() => _skills = v),
        ),
        const SizedBox(height: 14),
        FieldLabel(
          'Attachments (optional)',
          trailing: Text(
            '${_attachments.length} files',
            style: TextStyle(fontSize: 9, color: context.textSubColor),
          ),
        ),
        for (final f in _attachments) ...[
          MenuTile(
            icon: Icons.insert_drive_file_outlined,
            color: AppColors.tintRed,
            title: f,
            subtitle: 'Tap to remove',
            onTap: () => setState(
              () => _attachments = _attachments.where((x) => x != f).toList(),
            ),
            trailing: Icon(
              Icons.close_rounded,
              size: 16,
              color: context.textSubColor,
            ),
          ),
          const SizedBox(height: 6),
        ],
        OutlinedButton.icon(
          onPressed: () => setState(
            () => _attachments = [
              ..._attachments,
              'Brief_${_attachments.length + 1}.pdf',
            ],
          ),
          icon: const Icon(Icons.attach_file_rounded, size: 16),
          label: const Text('Add brief, mockups or references'),
        ),
      ],
    ),
  );

  Widget _budget() => Form(
    key: _formKeys[1],
    child: ListView(
      padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
      children: [
        const FieldLabel('How do you want to pay?', required: true),
        Row(
          children: [
            Expanded(
              child: _PricingTile(
                icon: Icons.request_quote_outlined,
                title: 'Fixed Price',
                subtitle: 'Pay per milestone',
                selected: _isFixed,
                onTap: () => setState(() => _pricing = PricingType.fixed),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PricingTile(
                icon: Icons.timer_outlined,
                title: 'Hourly Rate',
                subtitle: 'Pay for hours worked',
                selected: !_isFixed,
                onTap: () => setState(() => _pricing = PricingType.hourly),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FieldLabel(
          _isFixed ? 'Project budget (₹)' : 'Hourly rate (₹ / hr)',
          required: true,
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _budgetMin,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 11, color: context.textMainColor),
                decoration: InputDecoration(
                  hintText: _isFixed ? 'Min e.g. 10000' : 'Min e.g. 500',
                  prefixIcon: const Icon(
                    Icons.currency_rupee_rounded,
                    size: 16,
                  ),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '') ?? 0;
                  if (n <= 0) return 'Enter minimum';
                  if (_isFixed && n < 500) return 'Min ₹500';
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('to', style: TextStyle(color: context.textSubColor)),
            ),
            Expanded(
              child: TextFormField(
                controller: _budgetMax,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 11, color: context.textMainColor),
                decoration: InputDecoration(
                  hintText: _isFixed ? 'Max e.g. 25000' : 'Max e.g. 1000',
                  prefixIcon: const Icon(
                    Icons.currency_rupee_rounded,
                    size: 16,
                  ),
                ),
                validator: (v) {
                  final max = int.tryParse(v ?? '') ?? 0;
                  final min = int.tryParse(_budgetMin.text) ?? 0;
                  if (max <= 0) return 'Enter maximum';
                  if (max < min) return 'Must be ≥ minimum';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _isFixed
              ? 'You fund one milestone at a time into escrow — money is released only when you approve the work.'
              : 'Hourly contracts are billed weekly from your wallet.',
          style: TextStyle(fontSize: 9, color: AppColors.secondary),
        ),
        const SizedBox(height: 14),
        ChipGroup(
          label: 'Project duration',
          options: projectDurations,
          value: _duration,
          required: true,
          onChanged: (v) => setState(() => _duration = v),
        ),
        const SizedBox(height: 14),
        const FieldLabel('Freelancer experience level'),
        for (final l in freelancerLevels) ...[
          MenuTile(
            icon: switch (l) {
              'Entry' => Icons.signal_cellular_alt_1_bar_rounded,
              'Intermediate' => Icons.signal_cellular_alt_2_bar_rounded,
              _ => Icons.signal_cellular_alt_rounded,
            },
            color: switch (l) {
              'Entry' => AppColors.tintGreen,
              'Intermediate' => AppColors.tintBlue,
              _ => AppColors.tintPurple,
            },
            title: l,
            subtitle: _levelHints[l],
            onTap: () => setState(() => _level = l),
            trailing: Icon(
              _level == l
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: _level == l ? context.accentColor : context.textHintColor,
            ),
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 8),
        ChipGroup(
          label: 'Who can see this project?',
          options: const ['Public', 'Invite only'],
          value: _visibility,
          onChanged: (v) => setState(() => _visibility = v),
        ),
      ],
    ),
  );

  Widget _review() {
    final p = _build(ProjectStatus.open);
    return ListView(
      padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
      children: [
        Text(
          'This is how freelancers will see your project',
          style: TextStyle(fontSize: 10, color: context.textSubColor),
        ),
        const SizedBox(height: 8),
        ProjectPostCard(
          project: p,
          proposals: 0,
          newProposals: 0,
          onTap: () {},
        ),
        const SectionLabel('Summary'),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              InfoRow(label: 'Category', value: p.category),
              InfoRow(label: 'Payment', value: p.pricing.label),
              InfoRow(
                label: 'Budget',
                value: p.budgetLabel,
                valueColor: context.accentColor,
              ),
              InfoRow(label: 'Duration', value: p.duration),
              InfoRow(label: 'Experience', value: p.level),
              InfoRow(label: 'Visibility', value: _visibility),
              InfoRow(label: 'Skills', value: p.skills.join(', ')),
              if (p.attachments.isNotEmpty)
                InfoRow(label: 'Attachments', value: p.attachments.join(', ')),
            ],
          ),
        ),
        const SectionLabel('Description'),
        SoftCard(
          padding: const EdgeInsets.all(12),
          child: Text(
            p.description,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.5,
              color: context.textSubColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.tintGreen.withValues(
              alpha: context.isDark ? 0.15 : 0.08,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: AppColors.tintGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Posting is free. You pay only when you hire, through secure escrow.',
                  style: TextStyle(fontSize: 9.5, color: headingColor(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PricingTile extends StatelessWidget {
  const _PricingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected ? context.tagBgColor : context.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? context.accentColor : context.borderColor,
            width: selected ? 1.6 : 1.1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBubble(
                  icon: icon,
                  color: selected ? context.accentColor : AppColors.textSub,
                  size: 30,
                  iconSize: 15,
                ),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 17,
                  color: selected ? context.accentColor : context.textHintColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: headingColor(context),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9, color: context.textSubColor),
            ),
          ],
        ),
      ),
    );
  }
}
