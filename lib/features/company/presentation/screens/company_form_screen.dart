import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';

const _industries = [
  'Information Technology',
  'Software Product',
  'E-commerce',
  'Fintech',
  'EdTech',
  'Healthcare',
  'Marketing & Advertising',
  'Manufacturing',
  'Consulting',
  'Other',
];

const _sizes = [
  '1-10 employees',
  '11-50 employees',
  '51-200 employees',
  '201-1000 employees',
  '1000+ employees',
];

/// Company details. Shown once during onboarding ([onboarding] = true) and
/// later from Profile → Edit Company.
class CompanyFormScreen extends ConsumerStatefulWidget {
  const CompanyFormScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends ConsumerState<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CompanyModel _initial =
      ref.read(authProvider).user?.company ?? const CompanyModel();
  late final _name = TextEditingController(text: _initial.name);
  late final _website = TextEditingController(text: _initial.website);
  late final _location = TextEditingController(text: _initial.location);
  late final _founded = TextEditingController(text: _initial.founded);
  late final _gstin = TextEditingController(text: _initial.gstin);
  late final _about = TextEditingController(text: _initial.about);
  late String _industry = _initial.industry;
  late String _size = _initial.size;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _website, _location, _founded, _gstin, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await context.runApi(
      () => ref
          .read(authProvider.notifier)
          .updateCompany(
            _initial.copyWith(
              name: _name.text.trim(),
              industry: _industry,
              size: _size,
              website: _website.text.trim(),
              location: _location.text.trim(),
              founded: _founded.text.trim(),
              gstin: _gstin.text.trim(),
              about: _about.text.trim(),
            ),
          ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    if (widget.onboarding) {
      context.go(RoutePaths.home);
      context.showSnackBar('Welcome! Your hiring workspace is ready');
    } else {
      context.pop();
      context.showSnackBar('Company profile updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.onboarding,
        title: Text(widget.onboarding ? 'Set up your company' : 'Edit Company'),
        actions: [
          if (widget.onboarding)
            TextButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('Skip'),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
          children: [
            if (widget.onboarding) ...[
              const StepProgress(
                step: 1,
                steps: ['Hiring type', 'Company details'],
              ),
              const SizedBox(height: 12),
            ],
            SoftCard(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CompanyLogo(name: _name.text, size: 58),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company logo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: headingColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PNG or JPG, at least 200×200. Shown on all your job posts.',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: context.textSubColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: () =>
                              context.showSnackBar('Logo picker coming soon'),
                          icon: const Icon(Icons.upload_rounded, size: 15),
                          label: const Text('Upload logo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionLabel('Basic details'),
            LabeledField(
              label: 'Company name',
              controller: _name,
              icon: Icons.business_outlined,
              validator: (v) => Validators.required(v, field: 'Company name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            PickerField(
              label: 'Industry',
              value: _industry,
              options: _industries,
              icon: Icons.category_outlined,
              onChanged: (v) => setState(() => _industry = v),
            ),
            const SizedBox(height: 12),
            ChipGroup(
              label: 'Company size',
              options: _sizes,
              value: _size,
              onChanged: (v) => setState(() => _size = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Headquarters',
                    controller: _location,
                    icon: Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: LabeledField(
                    label: 'Founded',
                    controller: _founded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Website',
              controller: _website,
              icon: Icons.language_rounded,
              keyboardType: TextInputType.url,
            ),
            const SectionLabel('About the company'),
            LabeledField(
              label: 'Description',
              hint: 'What does your company do? What is it like to work there?',
              controller: _about,
              maxLines: 5,
            ),
            const SectionLabel('Verification'),
            LabeledField(
              label: 'GSTIN (optional)',
              controller: _gstin,
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 8),
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
                    Icons.verified_rounded,
                    size: 16,
                    color: AppColors.tintGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified companies get a blue tick and up to 3× more applicants.',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: headingColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: widget.onboarding ? 'Finish Setup' : 'Save Changes',
          loading: _saving,
          onPressed: _save,
        ),
      ),
    );
  }
}
