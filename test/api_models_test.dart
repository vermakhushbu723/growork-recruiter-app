import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subkamyaab_recruiter_app/core/network/api_client.dart';
import 'package:subkamyaab_recruiter_app/features/freelance/providers/client_projects_provider.dart';
import 'package:subkamyaab_recruiter_app/features/jobs/data/job_post_model.dart';
import 'package:subkamyaab_recruiter_app/features/jobs/providers/recruitment_provider.dart';
import 'package:subkamyaab_recruiter_app/features/talent/data/talent_model.dart';
import 'package:subkamyaab_recruiter_app/features/wallet/providers/wallet_provider.dart';
import 'package:subkamyaab_recruiter_app/shared/models/user_model.dart';
import 'package:subkamyaab_recruiter_app/shared/providers/activity_providers.dart';

import 'backend_helpers.dart';

/// Every list the recruiter app reads, fetched from the live API and parsed
/// into the app's models — catches any JSON shape mismatch.
void main() {
  setUpAll(() async {
    allowRealHttp();
    SharedPreferences.setMockInitialValues({});
    await loginDemo();
  });

  test('account + company parse', () async {
    final me = RecruiterUser.fromJson(jMap(await api.get('/auth/me')));
    expect(me.email, demoEmail);
    expect(me.company.name, 'Techify Solutions');
    expect(me.company.members, isNotEmpty);
    expect(me.company.members.any((m) => m.isOwner), isTrue);
  });

  test('jobs, applicants and interviews load', () async {
    final n = RecruitmentNotifier(autoLoad: false);
    await n.load();
    final s = n.state;
    expect(s.error, isNull);
    expect(s.jobs, isNotEmpty);
    expect(s.jobs.first.title, isNotEmpty);
    expect(s.jobs.first.salaryMax, greaterThan(0));
    expect(s.applicants, isNotEmpty);
    final a = s.applicants.first;
    expect(a.name, isNotEmpty);
    expect(a.candidateId, isNotEmpty);
    expect(a.email, contains('@'));
    expect(s.job(a.jobId), isNotNull, reason: 'applicant links to a job');
    expect(s.interviews, isNotEmpty);
    expect(s.interviews.first.candidateId, isNotEmpty);
  });

  test('projects, proposals and contracts load', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final n = ClientProjectsNotifier(
      container.read(Provider((ref) => ref)),
      autoLoad: false,
    );
    await n.load();
    final s = n.state;
    expect(s.error, isNull);
    expect(s.projects, isNotEmpty);
    expect(s.proposals, isNotEmpty);
    expect(s.proposals.first.freelancerId, isNotEmpty);
    expect(s.contracts, isNotEmpty);
    final c = s.contracts.first;
    expect(c.milestones, isNotEmpty);
    expect(c.freelancerId, isNotEmpty);
    expect(c.total, greaterThan(0));
  });

  test('wallet loads', () async {
    final n = WalletNotifier(autoLoad: false);
    await n.load();
    expect(n.state.loaded, isTrue);
    expect(n.state.plan, isNotEmpty);
    expect(n.state.transactions, isNotEmpty);
  });

  test('talent, chats, contacts, notifications load', () async {
    final talent = jMapList(
      await api.get('/talent'),
    ).map(TalentModel.fromJson).toList();
    expect(talent, isNotEmpty);
    expect(talent.first.skills, isNotEmpty);

    final chats = jMapList(
      await api.get('/chats'),
    ).map(ChatSummary.fromJson).toList();
    expect(chats, isNotEmpty);
    expect(chats.first.otherId, isNotEmpty);
    expect(chats.first.timeLabel, isNotEmpty);

    expect(jMapList(await api.get('/chats/contacts')), isNotEmpty);

    final notes = NotificationsNotifier(autoLoad: false);
    await notes.load();
    expect(notes.state.items, isNotEmpty);
  });

  test('job post round-trips through toJson', () async {
    final s = RecruitmentNotifier(autoLoad: false);
    await s.load();
    final job = s.state.jobs.first;
    final body = job.toJson();
    expect(body['title'], job.title);
    expect(body['status'], job.status.name);
    expect(JobPostStatus.values.map((e) => e.name), contains(body['status']));
  });
}
