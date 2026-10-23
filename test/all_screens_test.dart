import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:subkamyaab_recruiter_app/app.dart';
import 'package:subkamyaab_recruiter_app/core/network/api_client.dart';
import 'package:subkamyaab_recruiter_app/core/router/app_router.dart';
import 'package:subkamyaab_recruiter_app/core/router/route_paths.dart';
import 'package:subkamyaab_recruiter_app/core/theme/theme_provider.dart';
import 'package:subkamyaab_recruiter_app/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:subkamyaab_recruiter_app/features/chat/presentation/screens/call_screen.dart';
import 'package:subkamyaab_recruiter_app/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:subkamyaab_recruiter_app/features/jobs/data/job_post_model.dart';
import 'package:subkamyaab_recruiter_app/features/jobs/presentation/screens/applicants_screen.dart';

import 'backend_helpers.dart';

const _tabs = {
  RoutePaths.home,
  RoutePaths.jobs,
  RoutePaths.projects,
  RoutePaths.chat,
  RoutePaths.profile,
};

/// Real ids from the seeded backend.
Future<Map<String, String>> _fetchIds() async {
  String first(Object? list, [bool Function(Map<String, dynamic>)? where]) {
    final items = jMapList(list).where(where ?? (_) => true).toList();
    expect(items, isNotEmpty, reason: 'seed data missing');
    return jStr(items.first['id']);
  }

  return {
    'job': first(await api.get('/recruiter/jobs')),
    'applicant': first(await api.get('/recruiter/applicants')),
    'project': first(await api.get('/client/projects')),
    'openProject': first(
      await api.get('/client/projects'),
      (p) => p['status'] == 'open',
    ),
    'proposal': first(
      await api.get('/client/proposals'),
      (p) => p['status'] != 'hired',
    ),
    'contract': first(await api.get('/contracts')),
    'talent': first(await api.get('/talent')),
    'chat': first(await api.get('/chats')),
  };
}

List<(String, Object?)> _screens(Map<String, String> id) => [
  (RoutePaths.home, null),
  (RoutePaths.jobs, null),
  (RoutePaths.projects, null),
  (RoutePaths.chat, null),
  (RoutePaths.profile, null),
  (RoutePaths.login, null),
  (RoutePaths.signup, null),
  (RoutePaths.forgotPassword, null),
  (RoutePaths.otpVerification, null),
  (
    RoutePaths.otpVerification,
    const OtpArgs(target: 'a@b.com', reset: true, devOtp: '1234'),
  ),
  (RoutePaths.accountType, null),
  (RoutePaths.companySetup, null),
  (RoutePaths.postJob, null),
  (RoutePaths.postJob, id['job']),
  (RoutePaths.jobDetails, id['job']),
  (RoutePaths.applicants, null),
  (RoutePaths.applicants, id['job']),
  (RoutePaths.applicants, ApplicantStatus.shortlisted),
  (RoutePaths.applicants, ApplicantsArgs(jobId: id['job'])),
  (RoutePaths.applicantProfile, id['applicant']),
  (RoutePaths.scheduleInterview, id['applicant']),
  (RoutePaths.interviews, null),
  (RoutePaths.sendOffer, id['applicant']),
  (RoutePaths.postProject, null),
  (RoutePaths.postProject, id['openProject']),
  (RoutePaths.projectDetails, id['project']),
  (RoutePaths.projectDetails, id['openProject']),
  (RoutePaths.proposals, id['openProject']),
  (RoutePaths.proposalDetails, id['proposal']),
  (RoutePaths.hireFreelancer, id['proposal']),
  (RoutePaths.contracts, null),
  (RoutePaths.contract, id['contract']),
  (RoutePaths.endContract, id['contract']),
  (RoutePaths.talentSearch, null),
  (RoutePaths.talentProfile, id['talent']),
  (RoutePaths.savedTalent, null),
  (
    RoutePaths.chatRoom,
    ChatTarget(conversationId: id['chat'], name: 'Demo chat'),
  ),
  (RoutePaths.newChat, null),
  (RoutePaths.call, const CallArgs(name: 'Khushbu Verma', video: true)),
  (RoutePaths.notifications, null),
  (RoutePaths.wallet, null),
  (RoutePaths.addMoney, null),
  (RoutePaths.withdraw, null),
  (RoutePaths.plans, null),
  (RoutePaths.editCompany, null),
  (RoutePaths.editProfile, null),
  (RoutePaths.team, null),
  (RoutePaths.analytics, null),
  (RoutePaths.reviews, null),
  (RoutePaths.settings, null),
  (RoutePaths.language, null),
  (RoutePaths.privacy, null),
  (RoutePaths.help, null),
];

/// Seed values that must be visible once a screen has loaded its data.
const _mustShow = {
  RoutePaths.jobs: 'Flutter Developer',
  RoutePaths.projects: 'Logo & Brand Identity Design',
  RoutePaths.chat: 'Khushbu Verma',
  RoutePaths.profile: 'Techify Solutions',
  RoutePaths.interviews: 'Priya Sharma',
  RoutePaths.contracts: 'Build a React Admin Dashboard',
  RoutePaths.notifications: 'New Applicant',
  RoutePaths.talentSearch: 'Khushbu Verma',
  RoutePaths.team: 'Vivek Rao',
  RoutePaths.reviews: 'Priya Sharma',
};

/// Lets real network calls finish, then pumps frames. Keeps going (up to
/// ~10 s) while a loading spinner is on screen.
Future<void> _settle(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump(const Duration(milliseconds: 250));
    final loading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    if (i + 1 >= rounds && !loading) break;
  }
}

Future<void> _runAll(WidgetTester tester, {required bool dark}) async {
  allowRealHttp();
  // 360 × 780 dp phone, the size the user app was designed for.
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});

  late Map<String, String> ids;
  await tester.runAsync(() async {
    await loginDemo();
    ids = await _fetchIds();
  });

  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (dark) container.read(themeModeProvider.notifier).toggle(true);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RecruiterApp(),
    ),
  );
  final GoRouter router = container.read(routerProvider);
  // Splash → session restore (real API) → home.
  for (var i = 0; i < 40; i++) {
    await _settle(tester, rounds: 1);
    if (router.routerDelegate.currentConfiguration.uri.path ==
        RoutePaths.home) {
      break;
    }
  }
  expect(
    router.routerDelegate.currentConfiguration.uri.path,
    RoutePaths.home,
    reason: 'session restore did not reach home',
  );

  for (final (path, extra) in _screens(ids)) {
    router.go(RoutePaths.home);
    await _settle(tester, rounds: 1);
    if (_tabs.contains(path)) {
      router.go(path);
    } else {
      router.push(path, extra: extra);
    }
    await _settle(tester);
    final error = tester.takeException();
    expect(
      error,
      isNull,
      reason:
          '$path (extra: $extra) threw while rendering:\n'
          '${error is FlutterError ? error.toStringDeep() : error}',
    );
    final mustShow = extra == null ? _mustShow[path] : null;
    if (mustShow != null) {
      expect(
        find.textContaining(mustShow, findRichText: true),
        findsWidgets,
        reason:
            '$path should show live data "$mustShow"; on screen: '
            '${find.byType(Text, skipOffstage: false).evaluate().map((e) => (e.widget as Text).data).whereType<String>().take(40).join(' | ')} '
            '|| slivers=${find.byType(SliverToBoxAdapter).evaluate().length} '
            'spinners=${find.byType(CircularProgressIndicator).evaluate().length}',
      );
    }
  }
  router.go(RoutePaths.home);
  await _settle(tester);
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUpAll(loadInter);

  testWidgets('every screen renders with live data (light)', (tester) async {
    await _runAll(tester, dark: false);
  });

  testWidgets('every screen renders with live data (dark)', (tester) async {
    await _runAll(tester, dark: true);
  });
}
