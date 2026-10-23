import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../shared/providers/settings_provider.dart';

/// App language picker.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  static const _languages = [
    ('English', 'English'),
    ('हिन्दी', 'Hindi'),
    ('मराठी', 'Marathi'),
    ('বাংলা', 'Bengali'),
    ('தமிழ்', 'Tamil'),
    ('తెలుగు', 'Telugu'),
    ('ગુજરાતી', 'Gujarati'),
  ];
  String get _selected => ref.watch(settingsProvider.notifier).language;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          Text(
            'Choose the language for menus and messages',
            style: TextStyle(fontSize: 10, color: context.textSubColor),
          ),
          const SizedBox(height: 10),
          for (final l in _languages) ...[
            MenuTile(
              icon: Icons.translate_rounded,
              color: AppColors.tintBlue,
              title: l.$1,
              subtitle: l.$2,
              onTap: () {
                context.runApi(
                  () => ref
                      .read(settingsProvider.notifier)
                      .set('language', l.$2),
                );
                context.showSnackBar('Language set to ${l.$2}');
              },
              trailing: Icon(
                _selected == l.$2
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: _selected == l.$2
                    ? context.accentColor
                    : context.textHintColor,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

/// Profile visibility and account security toggles.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _flag(String key, {bool fallback = true}) {
    ref.watch(settingsProvider);
    return ref.read(settingsProvider.notifier).flag(key, fallback: fallback);
  }

  void _set(String key, bool v) =>
      context.runApi(() => ref.read(settingsProvider.notifier).set(key, v));

  Widget _toggle({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: MenuTile(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(value: value, onChanged: onChanged),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 0, 13, 20),
        children: [
          const SectionLabel('Privacy'),
          _toggle(
            icon: Icons.public_rounded,
            color: AppColors.tintBlue,
            title: 'Public company page',
            subtitle: 'Job seekers and freelancers can find you',
            value: _flag('publicProfile'),
            onChanged: (v) => _set('publicProfile', v),
          ),
          _toggle(
            icon: Icons.phone_outlined,
            color: AppColors.tintGreen,
            title: 'Show company phone',
            subtitle: 'Visible only to shortlisted candidates',
            value: _flag('showPhone', fallback: false),
            onChanged: (v) => _set('showPhone', v),
          ),
          _toggle(
            icon: Icons.chat_outlined,
            color: AppColors.tintPurple,
            title: 'Messages from candidates',
            subtitle: 'Let applicants message you before shortlisting',
            value: _flag('allowMessages'),
            onChanged: (v) => _set('allowMessages', v),
          ),
          const SectionLabel('Security'),
          _toggle(
            icon: Icons.shield_outlined,
            color: AppColors.tintOrange,
            title: 'Two-step verification',
            subtitle: 'OTP on every new login',
            value: _flag('twoStep', fallback: false),
            onChanged: (v) => _set('twoStep', v),
          ),
          MenuTile(
            icon: Icons.devices_rounded,
            color: AppColors.tintTeal,
            title: 'Active devices',
            subtitle: 'CPH2823 · This device',
            onTap: () => context.showSnackBar('You are signed in on 1 device'),
          ),
          const SizedBox(height: 6),
          MenuTile(
            icon: Icons.download_outlined,
            color: AppColors.tintBlue,
            title: 'Download my data',
            subtitle: 'Get a copy of your account data',
            onTap: () =>
                context.showSnackBar('We will email your data within 24h'),
          ),
        ],
      ),
    );
  }
}

/// FAQs and contact options.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'How do I post a job?',
      'Tap "Post Job" on the Jobs tab or Home, fill the 4 short steps and publish. Each post uses one job credit from your plan.',
    ),
    (
      'How do freelance payments work?',
      'You fund each milestone into escrow. The freelancer submits work, and money is released only when you approve it. Unused escrow is refunded if you end the contract.',
    ),
    (
      'How do I move candidates through hiring?',
      'Open an applicant and use Shortlist → Schedule Interview → Send Offer → Mark as Hired. You can move them to any stage from the ⋮ menu.',
    ),
    (
      'How do I get my company verified?',
      'Add your GSTIN and website in Edit Company Page. Verification usually takes 1 working day.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          GradientCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How can we help?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Our team replies within a few hours',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.support_agent_rounded,
                  size: 46,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (final (i, c) in const [
                (Icons.chat_rounded, 'Live Chat', AppColors.tintBlue),
                (Icons.mail_rounded, 'Email', AppColors.tintPurple),
                (Icons.call_rounded, 'Call Us', AppColors.tintGreen),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 7),
                Expanded(
                  child: SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    onTap: () => context.showSnackBar('${c.$2} support opened'),
                    child: Column(
                      children: [
                        IconBubble(icon: c.$1, color: c.$3, size: 34),
                        const SizedBox(height: 6),
                        Text(
                          c.$2,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: headingColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SectionLabel('Frequently asked questions'),
          for (final f in _faqs) ...[
            SoftCard(
              padding: EdgeInsets.zero,
              // Own Material so the tile's ink isn't hidden by the card.
              child: Material(
                type: MaterialType.transparency,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    iconColor: context.accentColor,
                    title: Text(
                      f.$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: headingColor(context),
                      ),
                    ),
                    children: [
                      Text(
                        f.$2,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.45,
                          color: context.textSubColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 6),
          MenuTile(
            icon: Icons.bug_report_outlined,
            color: AppColors.tintRed,
            title: 'Report a problem',
            subtitle: 'Something not working? Tell us',
            onTap: () =>
                context.showSnackBar('Thanks! Our team will look into it'),
          ),
        ],
      ),
    );
  }
}
