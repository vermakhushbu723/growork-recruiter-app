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
import '../../providers/recruitment_provider.dart';

class SendOfferScreen extends ConsumerStatefulWidget {
  const SendOfferScreen({super.key, required this.applicantId});

  final String applicantId;

  @override
  ConsumerState<SendOfferScreen> createState() => _SendOfferScreenState();
}

class _SendOfferScreenState extends ConsumerState<SendOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _hiring = ref.read(recruitmentProvider);
  late final _applicant = _hiring.applicant(widget.applicantId);
  late final _job = _applicant == null ? null : _hiring.job(_applicant.jobId);
  late final _designation = TextEditingController(text: _job?.title);
  late final _ctc = TextEditingController(
    text: _job == null
        ? ''
        : _job.salaryMax == _job.salaryMax.roundToDouble()
        ? '${_job.salaryMax.toInt()}'
        : '${_job.salaryMax}',
  );
  final _message = TextEditingController(
    text:
        'We loved meeting you and are excited to offer you this role. Please review the attached offer letter.',
  );
  DateTime _joining = DateTime.now().add(const Duration(days: 30));
  String _probation = '3 months';
  bool _attachLetter = true;
  bool _busy = false;
  String? _sentSummary;

  bool get _isInternship => _job?.isInternship ?? false;

  @override
  void dispose() {
    _designation.dispose();
    _ctc.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    String? summary;
    final ok = await context.runApi(() async {
      summary = await ref
          .read(recruitmentProvider.notifier)
          .sendOffer(
            applicantId: widget.applicantId,
            designation: _designation.text.trim(),
            amount: double.parse(_ctc.text.trim()),
            joiningDate: _joining,
            probation: _probation,
            message: _message.text.trim(),
          );
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _sentSummary = summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = _applicant;
    if (a == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Candidate not found',
        ),
      );
    }
    final sent = _sentSummary;
    if (sent != null) {
      return SuccessView(
        icon: Icons.mark_email_read_rounded,
        color: AppColors.tintTeal,
        title: 'Offer Sent!',
        message:
            '${a.name} will receive the offer by email and in the app. You will be notified when they respond.',
        details: SoftCard(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              InfoRow(label: 'Designation', value: _designation.text),
              InfoRow(label: 'Offer', value: sent.replaceFirst('Offer: ', '')),
              InfoRow(label: 'Probation', value: _probation),
            ],
          ),
        ),
        primaryLabel: 'Back to Candidate',
        onPrimary: () => context.pop(),
        secondaryLabel: 'View Applicants',
        onSecondary: () => context.pushReplacement(RoutePaths.applicants),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Send Offer')),
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
                          'Expects ${a.expectedSalary} · Notice ${a.noticePeriod}',
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
            const SectionLabel('Offer details'),
            LabeledField(
              label: 'Designation',
              controller: _designation,
              icon: Icons.badge_outlined,
              validator: (v) => Validators.required(v, field: 'Designation'),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: _isInternship
                  ? 'Monthly stipend (₹ thousands)'
                  : 'Annual CTC (₹ lakhs)',
              controller: _ctc,
              icon: Icons.currency_rupee_rounded,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Enter the offered amount'
                  : null,
            ),
            const SizedBox(height: 12),
            const FieldLabel('Joining date'),
            MenuTile(
              icon: Icons.event_outlined,
              color: AppColors.tintBlue,
              title: DateFormat('EEEE, d MMM yyyy').format(_joining),
              subtitle: 'Tap to change',
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _joining,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                );
                if (picked != null) setState(() => _joining = picked);
              },
            ),
            const SizedBox(height: 14),
            ChipGroup(
              label: 'Probation period',
              options: const ['None', '1 month', '3 months', '6 months'],
              value: _probation,
              onChanged: (v) => setState(() => _probation = v),
            ),
            const SectionLabel('Offer letter'),
            MenuTile(
              icon: Icons.picture_as_pdf_rounded,
              color: AppColors.tintRed,
              title: 'Offer_Letter_${a.name.split(' ').first}.pdf',
              subtitle: 'Auto-generated from your company template',
              onTap: () => setState(() => _attachLetter = !_attachLetter),
              trailing: Checkbox(
                value: _attachLetter,
                onChanged: (v) => setState(() => _attachLetter = v ?? false),
              ),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Message to candidate',
              controller: _message,
              maxLines: 4,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: 'Send Offer',
          icon: Icons.send_rounded,
          loading: _busy,
          onPressed: _send,
        ),
      ),
    );
  }
}
