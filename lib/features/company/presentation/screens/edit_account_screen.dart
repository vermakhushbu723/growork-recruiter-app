import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/providers/auth_provider.dart';

/// The recruiter's own details (not the company's).
class EditAccountScreen extends ConsumerStatefulWidget {
  const EditAccountScreen({super.key});

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _user = ref.read(authProvider).user;
  late final _name = TextEditingController(text: _user?.name);
  late final _email = TextEditingController(text: _user?.email);
  late final _phone = TextEditingController(
    text: _user?.phone.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst('91', ''),
  );
  late final _designation = TextEditingController(text: _user?.designation);
  final _linkedin = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _designation, _linkedin]) {
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
          .updateProfile(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: '+91 ${_phone.text.trim()}',
            designation: _designation.text.trim(),
          ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    context.pop();
    context.showSnackBar('Account updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(name: _name.text, size: 78),
                  Positioned(
                    right: -2,
                    bottom: 2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SectionLabel('Personal details'),
            LabeledField(
              label: 'Full name',
              controller: _name,
              icon: Icons.person_outline_rounded,
              validator: (v) => Validators.required(v, field: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Designation',
              controller: _designation,
              icon: Icons.badge_outlined,
              hint: 'e.g. HR Manager, Founder',
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Work email',
              controller: _email,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Phone',
              controller: _phone,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'LinkedIn (optional)',
              controller: _linkedin,
              icon: Icons.link_rounded,
            ),
            const SectionLabel('Security'),
            MenuTile(
              icon: Icons.lock_reset_outlined,
              color: AppColors.tintOrange,
              title: 'Change Password',
              subtitle: 'Reset via email OTP',
              onTap: () => context.push(RoutePaths.forgotPassword),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: 'Save Changes',
          loading: _saving,
          onPressed: _save,
        ),
      ),
    );
  }
}
