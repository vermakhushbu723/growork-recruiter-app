import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class WalletTransaction {
  const WalletTransaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
    required this.icon,
  });

  final String title;
  final String date;
  final int amount;
  final bool isCredit;
  final IconData icon;

  static IconData iconFor(String kind) => switch (kind) {
    'escrowFund' => Icons.lock_rounded,
    'escrowRelease' => Icons.lock_open_rounded,
    'escrowRefund' => Icons.replay_rounded,
    'withdrawal' => Icons.account_balance_rounded,
    'topup' => Icons.add_card_rounded,
    'plan' => Icons.workspace_premium_rounded,
    'payout' => Icons.laptop_rounded,
    _ => Icons.receipt_long_rounded,
  };

  factory WalletTransaction.fromJson(Map<String, dynamic> j) =>
      WalletTransaction(
        title: jStr(j['title']),
        date: DateFormat(
          'd MMM yyyy · h:mm a',
        ).format((jDate(j['createdAt']) ?? DateTime.now()).toLocal()),
        amount: jInt(j['amount']),
        isCredit: jBool(j['isCredit']),
        icon: iconFor(jStr(j['kind'])),
      );
}

/// A hiring plan: how many job posts it includes and what it costs.
/// Mirrors `GET /plans` on the server.
class HiringPlan {
  const HiringPlan({
    required this.name,
    required this.price,
    required this.jobCredits,
    required this.features,
    this.popular = false,
  });

  final String name;
  final int price;
  final int jobCredits;
  final List<String> features;
  final bool popular;
}

const List<HiringPlan> hiringPlans = [
  HiringPlan(
    name: 'Starter',
    price: 0,
    jobCredits: 2,
    features: [
      '2 job posts per month',
      'Unlimited freelance projects',
      'Basic applicant filters',
    ],
  ),
  HiringPlan(
    name: 'Growth',
    price: 2999,
    jobCredits: 15,
    popular: true,
    features: [
      '15 job posts per month',
      'Urgent hiring badge',
      'AI resume match scores',
      'Talent search & invites',
    ],
  ),
  HiringPlan(
    name: 'Enterprise',
    price: 9999,
    jobCredits: 60,
    features: [
      '60 job posts per month',
      'Featured company page',
      'Team accounts (up to 10)',
      'Dedicated account manager',
    ],
  ),
];

class WalletState {
  const WalletState({
    this.balance = 0,
    this.escrow = 0,
    this.spentThisMonth = 0,
    this.transactions = const [],
    this.plan = 'Starter',
    this.jobCredits = 0,
    this.loaded = false,
  });

  final int balance;
  final int escrow;
  final int spentThisMonth;
  final List<WalletTransaction> transactions;
  final String plan;
  final int jobCredits;
  final bool loaded;

  factory WalletState.fromJson(Map<String, dynamic> j) => WalletState(
    balance: jInt(j['balance']),
    escrow: jInt(j['escrow']),
    spentThisMonth: jInt(j['spentThisMonth']),
    plan: jStr(j['plan'], 'Starter'),
    jobCredits: jInt(j['jobCredits']),
    transactions: jMapList(
      j['transactions'],
    ).map(WalletTransaction.fromJson).toList(),
    loaded: true,
  );
}

/// The company wallet. All money movement is decided by the server; this
/// just mirrors it. Methods throw [ApiException] (402 = not enough balance).
class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier({bool autoLoad = true}) : super(const WalletState()) {
    if (autoLoad) load();
  }

  Future<void> load() async {
    try {
      final data = await api.get('/wallet');
      if (mounted) state = WalletState.fromJson(jMap(data));
    } on ApiException catch (_) {
      if (mounted && !state.loaded) state = const WalletState(loaded: true);
    }
  }

  Future<void> addMoney(int amount, String method) async {
    await api.post('/wallet/add-money', {'amount': amount, 'method': method});
    await load();
  }

  Future<void> withdraw(int amount, String to) async {
    await api.post('/wallet/withdraw', {'amount': amount, 'method': to});
    await load();
  }

  /// Buys a plan, or with [addOn] just its credits (keeps the current plan).
  Future<void> buyPlan(HiringPlan plan, {bool addOn = false}) async {
    await api.post('/wallet/plans/buy', {'plan': plan.name, 'addOn': addOn});
    await load();
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((
  ref,
) {
  final userId = ref.watch(sessionUserIdProvider);
  return WalletNotifier(autoLoad: userId != null);
});
