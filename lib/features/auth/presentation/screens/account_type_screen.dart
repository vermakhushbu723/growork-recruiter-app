import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/models/account_type.dart';
import '../../providers/auth_provider.dart';

/// "How will you hire?" — picked after signup, changeable from Settings.
class AccountTypeScreen extends ConsumerStatefulWidget {
  const AccountTypeScreen({super.key, this.fromSettings = false});

  /// When opened from Settings, saving goes back instead of onboarding on.
  final bool fromSettings;

  @override
  ConsumerState<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends ConsumerState<AccountTypeScreen> {
  late AccountType _selected =
      ref.read(authProvider).user?.accountType ?? AccountType.both;

  static const _types = [
    (type: AccountType.recruiter, icon: Icons.work_outline_rounded),
    (type: AccountType.client, icon: Icons.laptop_mac_rounded),
    (type: AccountType.both, icon: Icons.groups_2_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.fromSettings
          ? AppBar(title: const Text('Hiring For'))
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: widget.fromSettings ? 4 : 24),
              Text(
                'How will you hire on Subkamyaab?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'You can post both jobs and projects anytime — this sets your home screen',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: _types.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = _types[index];
                    final isSelected = _selected == item.type;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _selected = item.type),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.tagBgColor
                              : context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? context.accentColor
                                : context.borderColor,
                            width: isSelected ? 1.8 : 1.2,
                          ),
                          boxShadow: context.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : context.tagBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                color: isSelected
                                    ? Colors.white
                                    : context.accentColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.type.label,
                                    style: context.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    item.type.description,
                                    style: context.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSelected
                                  ? context.accentColor
                                  : context.textHintColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await context.runApi(
                      () => ref
                          .read(authProvider.notifier)
                          .setAccountType(_selected),
                    );
                    if (!ok || !context.mounted) return;
                    if (widget.fromSettings) {
                      context.pop();
                      context.showSnackBar('Now hiring as ${_selected.label}');
                    } else {
                      context.go(RoutePaths.companySetup);
                    }
                  },
                  child: Text(widget.fromSettings ? 'Save' : 'Continue'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
