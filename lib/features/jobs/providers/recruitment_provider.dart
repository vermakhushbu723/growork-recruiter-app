import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/job_post_model.dart';

class RecruitmentState {
  const RecruitmentState({
    this.jobs = const [],
    this.applicants = const [],
    this.interviews = const [],
    this.loaded = false,
    this.error,
  });

  final List<JobPost> jobs;
  final List<Applicant> applicants;
  final List<Interview> interviews;

  /// True once the first load finished (successfully or not).
  final bool loaded;
  final String? error;

  JobPost? job(String id) {
    for (final j in jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  Applicant? applicant(String id) {
    for (final a in applicants) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<Applicant> applicantsFor(String jobId) =>
      applicants.where((a) => a.jobId == jobId).toList();

  int countFor(String jobId, ApplicantStatus status) =>
      applicants.where((a) => a.jobId == jobId && a.status == status).length;

  List<JobPost> get activeJobs =>
      jobs.where((j) => j.status == JobPostStatus.active).toList();

  List<Interview> get upcomingInterviews =>
      interviews.where((i) => i.status == InterviewStatus.scheduled).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  int get newApplicants =>
      applicants.where((a) => a.status == ApplicantStatus.applied).length;

  int get totalHired =>
      applicants.where((a) => a.status == ApplicantStatus.hired).length;

  RecruitmentState copyWith({
    List<JobPost>? jobs,
    List<Applicant>? applicants,
    List<Interview>? interviews,
    bool? loaded,
    String? error,
  }) => RecruitmentState(
    jobs: jobs ?? this.jobs,
    applicants: applicants ?? this.applicants,
    interviews: interviews ?? this.interviews,
    loaded: loaded ?? this.loaded,
    error: error,
  );
}

/// Job posts, applicants and interviews for the signed-in recruiter's
/// company. Every change goes to the API first; the state then mirrors
/// the server's answer. Methods throw [ApiException] on failure.
class RecruitmentNotifier extends StateNotifier<RecruitmentState> {
  RecruitmentNotifier({bool autoLoad = true})
    : super(const RecruitmentState()) {
    if (autoLoad) load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        api.get('/recruiter/jobs'),
        api.get('/recruiter/applicants'),
        api.get('/recruiter/interviews'),
      ]);
      if (!mounted) return;
      state = RecruitmentState(
        jobs: jMapList(results[0]).map(JobPost.fromJson).toList(),
        applicants: jMapList(results[1]).map(Applicant.fromJson).toList(),
        interviews: jMapList(results[2]).map(Interview.fromJson).toList(),
        loaded: true,
      );
    } on ApiException catch (e) {
      if (mounted) state = state.copyWith(loaded: true, error: e.message);
    }
  }

  void _putJob(JobPost job) {
    final exists = state.jobs.any((j) => j.id == job.id);
    state = state.copyWith(
      jobs: exists
          ? [for (final j in state.jobs) j.id == job.id ? job : j]
          : [job, ...state.jobs],
    );
  }

  void _putApplicant(Applicant a) => state = state.copyWith(
    applicants: [for (final x in state.applicants) x.id == a.id ? a : x],
  );

  /// Creates a post (empty id) or saves changes to an existing one.
  /// Returns the saved post with its server id.
  Future<JobPost> saveJob(JobPost job) async {
    final isNew = job.id.isEmpty || state.job(job.id) == null;
    final data = isNew
        ? await api.post('/recruiter/jobs', job.toJson())
        : await api.patch('/recruiter/jobs/${job.id}', job.toJson());
    final saved = JobPost.fromJson(jMap(data));
    _putJob(saved);
    return saved;
  }

  Future<void> setJobStatus(String jobId, JobPostStatus status) async {
    final data = await api.patch('/recruiter/jobs/$jobId/status', {
      'status': status.name,
    });
    _putJob(JobPost.fromJson(jMap(data)));
  }

  Future<void> deleteJob(String jobId) async {
    await api.delete('/recruiter/jobs/$jobId');
    state = state.copyWith(
      jobs: state.jobs.where((j) => j.id != jobId).toList(),
      applicants: state.applicants.where((a) => a.jobId != jobId).toList(),
    );
  }

  /// Copies a post as a new draft.
  Future<JobPost> duplicateJob(String jobId) async {
    final copy = JobPost.fromJson(
      jMap(await api.post('/recruiter/jobs/$jobId/duplicate')),
    );
    _putJob(copy);
    return copy;
  }

  Future<void> setApplicantStatus(
    String applicantId,
    ApplicantStatus status,
  ) async {
    final data = await api.patch('/recruiter/applicants/$applicantId', {
      'status': status.name,
    });
    _putApplicant(Applicant.fromJson(jMap(data)));
  }

  Future<void> saveNote(String applicantId, String note) async {
    final data = await api.patch('/recruiter/applicants/$applicantId', {
      'note': note,
    });
    _putApplicant(Applicant.fromJson(jMap(data)));
  }

  Future<Interview> scheduleInterview({
    required String applicantId,
    required DateTime dateTime,
    required InterviewMode mode,
    required String round,
    required int durationMins,
    required String interviewer,
    required String link,
    String message = '',
  }) async {
    final data = await api.post('/recruiter/interviews', {
      'applicationId': applicantId,
      'dateTime': dateTime.toUtc().toIso8601String(),
      'mode': mode.name,
      'round': round,
      'durationMins': durationMins,
      'interviewer': interviewer,
      'link': link,
      'message': message,
    });
    final iv = Interview.fromJson(jMap(data));
    state = state.copyWith(
      interviews: [iv, ...state.interviews],
      applicants: [
        for (final a in state.applicants)
          a.id == applicantId
              ? a.copyWith(status: ApplicantStatus.interview)
              : a,
      ],
    );
    return iv;
  }

  Future<void> setInterviewStatus(
    String interviewId,
    InterviewStatus status,
  ) async {
    final iv = Interview.fromJson(
      jMap(
        await api.patch('/recruiter/interviews/$interviewId', {
          'status': status.name,
        }),
      ),
    );
    state = state.copyWith(
      interviews: [
        for (final i in state.interviews) i.id == interviewId ? iv : i,
      ],
    );
  }

  /// Sends the offer; returns the summary line saved on the applicant.
  Future<String> sendOffer({
    required String applicantId,
    required String designation,
    required double amount,
    required DateTime joiningDate,
    required String probation,
    String message = '',
  }) async {
    final data = await api.post('/recruiter/applicants/$applicantId/offer', {
      'designation': designation,
      'amount': amount,
      'joiningDate': joiningDate.toUtc().toIso8601String(),
      'probation': probation,
      'message': message,
    });
    final a = Applicant.fromJson(jMap(data));
    _putApplicant(a);
    return a.note ?? '';
  }
}

final recruitmentProvider =
    StateNotifierProvider<RecruitmentNotifier, RecruitmentState>((ref) {
      // Reload from scratch whenever a different account signs in.
      final userId = ref.watch(sessionUserIdProvider);
      return RecruitmentNotifier(autoLoad: userId != null);
    });
