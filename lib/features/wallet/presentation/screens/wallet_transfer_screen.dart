import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../freelance/data/project_models.dart';
import '../../providers/wallet_provider.dart';

/// Shared screen for "Add Money" (to fund escrow & plans) and "Withdraw".
class WalletTransferScreen extends ConsumerStatefulWidget {
  const WalletTransferScreen({super.key, required this.withdraw});

  final bool withdraw;

  @override
  ConsumerState<WalletTransferScreen> createState() =>
      _WalletTransferScreenState();
}

class _WalletTransferScreenState extends ConsumerState<WalletTransferScreen> {
  final _amount = TextEditingController();
  int _method = 0;
  bool _busy = false;

  List<(IconData, String, String)> get _methods => widget.withdraw
      ? const [
          (
            Icons.account_balance_rounded,
            'Linked bank account',
            'Company current account',
          ),
          (Icons.qr_code_rounded, 'UPI', 'Instant transfer'),
        ]
      : const [
          (Icons.qr_code_rounded, 'UPI', 'GPay, PhonePe, Paytm'),
          (Icons.account_balance_rounded, 'Net Banking', 'All major banks'),
          (
            Icons.credit_card_rounded,
            'Corporate Card',
            'Visa, Mastercard, RuPay',
          ),
        ];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = int.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    final balance = ref.read(walletProvider).balance;
    if (value < 100) {
      context.showSnackBar('Enter at least ₹100', isError: true);
      return;
    }
    if (widget.withdraw && value > balance) {
      context.showSnackBar('Amount exceeds your balance', isError: true);
      return;
    }
    setState(() => _busy = true);
    final notifier = ref.read(walletProvider.notifier);
    final method = _methods[_method].$2;
    final ok = await context.runApi(
      () => widget.withdraw
          ? notifier.withdraw(value, method)
          : notifier.addMoney(value, method),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    Navigator.of(context).pop();
    context.showSnackBar(
      widget.withdraw
          ? '${formatRupees(value)} withdrawal requested · arrives in 1-2 days'
          : '${formatRupees(value)} added to your wallet',
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.withdraw ? 'Withdraw' : 'Add Money';
    final balance = ref.watch(walletProvider).balance;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Text(
                  widget.withdraw
                      ? 'Available balance ${formatRupees(balance)}'
                      : 'Wallet balance ${formatRupees(balance)}',
                  style: TextStyle(fontSize: 10, color: context.textSubColor),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: headingColor(context),
                  ),
                  decoration: const InputDecoration(
                    hintText: '₹0',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final v in const [5000, 10000, 25000, 50000])
                      PillChip(
                        label: formatRupees(v),
                        selected: _amount.text == '$v',
                        onTap: () => setState(() => _amount.text = '$v'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SectionLabel(widget.withdraw ? 'Withdraw to' : 'Pay using'),
          for (final (i, m) in _methods.indexed) ...[
            MenuTile(
              icon: m.$1,
              color: AppColors.tintBlue,
              title: m.$2,
              subtitle: m.$3,
              onTap: () => setState(() => _method = i),
              trailing: Icon(
                _method == i
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: _method == i
                    ? context.accentColor
                    : context.textHintColor,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (!widget.withdraw) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.tintBlue.withValues(
                  alpha: context.isDark ? 0.15 : 0.07,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'Wallet money is used to fund freelance milestones and buy hiring plans. A GST invoice is generated for every top-up.',
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.4,
                  color: headingColor(context),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: context.textSubColor,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Payments are 100% secure and encrypted',
                  style: TextStyle(fontSize: 9, color: context.textSubColor),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: widget.withdraw ? 'Withdraw Now' : 'Proceed to Pay',
          loading: _busy,
          onPressed: _submit,
        ),
      ),
    );
  }
}
