import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

enum TalentKind { candidate, freelancer }

extension TalentKindX on TalentKind {
  String get label =>
      this == TalentKind.candidate ? 'Job Seeker' : 'Freelancer';
}

class TalentModel {
  const TalentModel({
    required this.id,
    required this.name,
    required this.headline,
    required this.kind,
    required this.location,
    required this.experience,
    required this.skills,
    required this.rate,
    required this.about,
    this.rating = 0,
    this.jobsDone = 0,
    this.available = true,
    this.education = '',
    this.portfolio = const [],
  });

  final String id;
  final String name;
  final String headline;
  final TalentKind kind;
  final String location;
  final String experience;
  final List<String> skills;

  /// Expected salary for job seekers, hourly rate for freelancers.
  final String rate;
  final String about;
  final double rating;
  final int jobsDone;
  final bool available;
  final String education;
  final List<String> portfolio;

  factory TalentModel.fromJson(Map<String, dynamic> j) => TalentModel(
    id: jStr(j['id']),
    name: jStr(j['name']),
    headline: jStr(j['headline']),
    kind: j['kind'] == 'freelancer'
        ? TalentKind.freelancer
        : TalentKind.candidate,
    location: jStr(j['location']),
    experience: jStr(j['experience'], '—').isEmpty
        ? '—'
        : jStr(j['experience']),
    skills: jStrList(j['skills']),
    rate: jStr(j['rate'], '—'),
    about: jStr(j['about']),
    rating: jDouble(j['rating']),
    jobsDone: jInt(j['jobsDone']),
    available: jBool(j['available'], true),
    education: jStr(j['education']),
    portfolio: jStrList(j['portfolio']).where((p) => p.isNotEmpty).toList(),
  );
}

/// Every public profile; the search screen filters it locally.
final talentListProvider = FutureProvider.autoDispose<List<TalentModel>>((
  ref,
) async {
  ref.watch(sessionUserIdProvider);
  return jMapList(await api.get('/talent')).map(TalentModel.fromJson).toList();
});

final talentProfileProvider = FutureProvider.autoDispose
    .family<TalentModel, String>((ref, id) async {
      return TalentModel.fromJson(jMap(await api.get('/talent/$id')));
    });

/// Saved (bookmarked) talent: ids for quick checks plus the full profiles.
class SavedTalentState {
  const SavedTalentState({this.ids = const {}, this.items = const []});

  final Set<String> ids;
  final List<TalentModel> items;

  bool contains(String id) => ids.contains(id);
}

class SavedTalentNotifier extends StateNotifier<SavedTalentState> {
  SavedTalentNotifier({bool autoLoad = true})
    : super(const SavedTalentState()) {
    if (autoLoad) load();
  }

  Future<void> load() async {
    try {
      final items = jMapList(
        await api.get('/saved', query: {'kind': 'talent'}),
      ).map(TalentModel.fromJson).toList();
      if (mounted) {
        state = SavedTalentState(
          ids: {for (final t in items) t.id},
          items: items,
        );
      }
    } on ApiException catch (_) {}
  }

  /// Saves or un-saves a profile; returns true if it is now saved.
  Future<bool> toggle(String id) async {
    final d = jMap(
      await api.post('/saved/toggle', {'kind': 'talent', 'ref': id}),
    );
    await load();
    return jBool(d['saved']);
  }
}

final savedTalentProvider =
    StateNotifierProvider<SavedTalentNotifier, SavedTalentState>((ref) {
      final userId = ref.watch(sessionUserIdProvider);
      return SavedTalentNotifier(autoLoad: userId != null);
    });

/// Invites a profile to apply to a job or bid on a project.
Future<void> inviteTalent(
  String talentId, {
  String? jobId,
  String? projectId,
}) => api.post('/talent/$talentId/invite', {
  'jobId': ?jobId,
  'projectId': ?projectId,
});
