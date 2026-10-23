import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';

/// Lifecycle of a job the recruiter has posted.
enum JobPostStatus { active, paused, draft, closed }

extension JobPostStatusX on JobPostStatus {
  String get label => switch (this) {
    JobPostStatus.active => 'Active',
    JobPostStatus.paused => 'Paused',
    JobPostStatus.draft => 'Draft',
    JobPostStatus.closed => 'Closed',
  };

  Color get color => switch (this) {
    JobPostStatus.active => AppColors.tintGreen,
    JobPostStatus.paused => AppColors.tintOrange,
    JobPostStatus.draft => AppColors.textSub,
    JobPostStatus.closed => AppColors.tintRed,
  };
}

/// Job types a recruiter can post. Internships are a job type, as in the
/// user app.
const List<String> jobPostTypes = [
  'Full-time',
  'Part-time',
  'Internship',
  'Contract',
];

const List<String> workModes = ['On-site', 'Remote', 'Hybrid'];

const List<String> experienceLevels = [
  'Fresher',
  'Junior Level',
  'Mid Level',
  'Senior Level',
];

const List<String> experienceRanges = [
  '0–1 yrs',
  '1–3 yrs',
  '2–4 yrs',
  '3–5 yrs',
  '5–8 yrs',
  '8+ yrs',
];

const List<String> jobCategories = [
  'Engineering',
  'Design',
  'Marketing',
  'Sales',
  'Operations',
  'Data & Analytics',
  'Customer Support',
  'HR & Admin',
];

const List<String> commonPerks = [
  'Health insurance',
  'Flexible work hours',
  'Work from home',
  'Performance bonus',
  'Paid leaves',
  'PPO opportunity',
  'Certificate',
  'Free meals',
];

class JobPost {
  const JobPost({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.workMode,
    required this.location,
    required this.salaryMin,
    required this.salaryMax,
    required this.experience,
    required this.level,
    required this.openings,
    required this.skills,
    required this.description,
    this.responsibilities = const [],
    this.perks = const [],
    this.status = JobPostStatus.active,
    this.postedAgo = 'Just now',
    this.deadline = '30 Nov 2026',
    this.views = 0,
    this.isUrgent = false,
    this.duration,
  });

  final String id;
  final String title;
  final String category;
  final String type;
  final String workMode;
  final String location;

  /// Yearly CTC in lakhs for jobs; monthly stipend in thousands for
  /// internships (see [salaryLabel]).
  final double salaryMin;
  final double salaryMax;
  final String experience;
  final String level;
  final int openings;
  final List<String> skills;
  final String description;
  final List<String> responsibilities;
  final List<String> perks;
  final JobPostStatus status;
  final String postedAgo;
  final String deadline;
  final int views;
  final bool isUrgent;

  /// Internship length, e.g. '3 months'.
  final String? duration;

  static final _deadlineFormat = DateFormat('d MMM yyyy');

  factory JobPost.fromJson(Map<String, dynamic> j) {
    final deadline = jDate(j['deadline']);
    final status = JobPostStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => JobPostStatus.active,
    );
    return JobPost(
      id: jStr(j['id']),
      title: jStr(j['title']),
      category: jStr(j['category']),
      type: jStr(j['type'], 'Full-time'),
      workMode: jStr(j['workMode'], 'On-site'),
      location: jStr(j['location']),
      salaryMin: jDouble(j['salaryMin']),
      salaryMax: jDouble(j['salaryMax']),
      experience: jStr(j['experience']),
      level: jStr(j['level']),
      openings: jInt(j['openings'], 1),
      skills: jStrList(j['skills']),
      description: jStr(j['description']),
      responsibilities: jStrList(j['responsibilities']),
      perks: jStrList(j['perks']),
      status: status,
      postedAgo: status == JobPostStatus.draft
          ? 'Not posted'
          : timeAgo(jDate(j['publishedAt']) ?? jDate(j['createdAt'])),
      deadline: deadline == null
          ? ''
          : _deadlineFormat.format(deadline.toLocal()),
      views: jInt(j['views']),
      isUrgent: jBool(j['isUrgent']),
      duration: j['duration'] as String?,
    );
  }

  /// Body for `POST /recruiter/jobs` and `PATCH /recruiter/jobs/:id`.
  Map<String, dynamic> toJson() {
    DateTime? deadlineDate;
    try {
      deadlineDate = deadline.isEmpty ? null : _deadlineFormat.parse(deadline);
    } catch (_) {}
    return {
      'title': title,
      'category': category,
      'type': type,
      'workMode': workMode,
      'location': location,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'experience': experience,
      'level': level,
      'openings': openings,
      'skills': skills,
      'description': description,
      'responsibilities': responsibilities,
      'perks': perks,
      'status': status.name,
      if (deadlineDate != null) 'deadline': deadlineDate.toIso8601String(),
      'isUrgent': isUrgent,
      'duration': duration,
    };
  }

  bool get isInternship => type == 'Internship';

  String _n(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  String get salaryLabel => isInternship
      ? '₹${_n(salaryMin)}K – ₹${_n(salaryMax)}K /month'
      : '₹${_n(salaryMin)}L – ₹${_n(salaryMax)}L /yr';

  String get shortSalary => isInternship
      ? '₹${_n(salaryMin)}–${_n(salaryMax)}K /mo'
      : '₹${_n(salaryMin)} – ${_n(salaryMax)} LPA';

  JobPost copyWith({
    String? title,
    String? category,
    String? type,
    String? workMode,
    String? location,
    double? salaryMin,
    double? salaryMax,
    String? experience,
    String? level,
    int? openings,
    List<String>? skills,
    String? description,
    List<String>? responsibilities,
    List<String>? perks,
    JobPostStatus? status,
    String? postedAgo,
    String? deadline,
    int? views,
    bool? isUrgent,
    String? duration,
  }) {
    return JobPost(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      type: type ?? this.type,
      workMode: workMode ?? this.workMode,
      location: location ?? this.location,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      experience: experience ?? this.experience,
      level: level ?? this.level,
      openings: openings ?? this.openings,
      skills: skills ?? this.skills,
      description: description ?? this.description,
      responsibilities: responsibilities ?? this.responsibilities,
      perks: perks ?? this.perks,
      status: status ?? this.status,
      postedAgo: postedAgo ?? this.postedAgo,
      deadline: deadline ?? this.deadline,
      views: views ?? this.views,
      isUrgent: isUrgent ?? this.isUrgent,
      duration: duration ?? this.duration,
    );
  }
}

/// Hiring pipeline stages for one application.
enum ApplicantStatus {
  applied,
  shortlisted,
  interview,
  offered,
  hired,
  rejected,
}

extension ApplicantStatusX on ApplicantStatus {
  String get label => switch (this) {
    ApplicantStatus.applied => 'New',
    ApplicantStatus.shortlisted => 'Shortlisted',
    ApplicantStatus.interview => 'Interview',
    ApplicantStatus.offered => 'Offered',
    ApplicantStatus.hired => 'Hired',
    ApplicantStatus.rejected => 'Rejected',
  };

  Color get color => switch (this) {
    ApplicantStatus.applied => AppColors.tintBlue,
    ApplicantStatus.shortlisted => AppColors.tintOrange,
    ApplicantStatus.interview => AppColors.tintPurple,
    ApplicantStatus.offered => AppColors.tintTeal,
    ApplicantStatus.hired => AppColors.tintGreen,
    ApplicantStatus.rejected => AppColors.tintRed,
  };

  IconData get icon => switch (this) {
    ApplicantStatus.applied => Icons.fiber_new_rounded,
    ApplicantStatus.shortlisted => Icons.star_rounded,
    ApplicantStatus.interview => Icons.event_rounded,
    ApplicantStatus.offered => Icons.local_offer_rounded,
    ApplicantStatus.hired => Icons.verified_rounded,
    ApplicantStatus.rejected => Icons.block_rounded,
  };
}

class Applicant {
  const Applicant({
    required this.id,
    required this.jobId,
    required this.name,
    required this.headline,
    required this.location,
    required this.experience,
    required this.skills,
    required this.expectedSalary,
    required this.noticePeriod,
    required this.matchScore,
    required this.appliedAgo,
    required this.coverLetter,
    this.status = ApplicantStatus.applied,
    this.education = 'B.Tech, Computer Science',
    this.email = 'candidate@mail.com',
    this.phone = '+91 90000 00000',
    this.currentCompany,
    this.resumeName = 'Resume.pdf',
    this.note,
    this.candidateId = '',
  });

  final String id;
  final String jobId;
  final String name;
  final String headline;
  final String location;
  final String experience;
  final List<String> skills;
  final String expectedSalary;
  final String noticePeriod;

  /// 0–100, how well the resume matches the job.
  final int matchScore;
  final String appliedAgo;
  final String coverLetter;
  final ApplicantStatus status;
  final String education;
  final String email;
  final String phone;
  final String? currentCompany;
  final String resumeName;

  /// Private recruiter note on the candidate.
  final String? note;

  /// The candidate's user id (for chat and their talent profile).
  final String candidateId;

  factory Applicant.fromJson(Map<String, dynamic> j) {
    final c = jMap(j['candidate']);
    final note = jStr(j['note']);
    return Applicant(
      id: jStr(j['id']),
      jobId: jStr(j['jobId']),
      candidateId: jStr(c['id']),
      name: jStr(c['name'], 'Candidate'),
      headline: jStr(c['headline']),
      location: jStr(c['location']),
      experience: jStr(c['experience'], '—'),
      skills: jStrList(c['skills']),
      expectedSalary: jStr(c['expectedSalary'], '—').isEmpty
          ? '—'
          : jStr(c['expectedSalary'], '—'),
      noticePeriod: jStr(j['noticePeriod'], jStr(c['noticePeriod'])),
      matchScore: jInt(j['matchScore']),
      appliedAgo: timeAgo(jDate(j['appliedAt'])),
      coverLetter: jStr(j['coverLetter']),
      status: ApplicantStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => ApplicantStatus.applied,
      ),
      education: jStr(c['education'], '—').isEmpty
          ? '—'
          : jStr(c['education'], '—'),
      email: jStr(c['email']),
      phone: jStr(c['phone']),
      currentCompany: jStr(c['currentCompany']).isEmpty
          ? null
          : jStr(c['currentCompany']),
      resumeName: jStr(j['resumeName'], 'Resume.pdf'),
      note: note.isEmpty ? null : note,
    );
  }

  Applicant copyWith({ApplicantStatus? status, String? note}) => Applicant(
    id: id,
    jobId: jobId,
    name: name,
    headline: headline,
    location: location,
    experience: experience,
    skills: skills,
    expectedSalary: expectedSalary,
    noticePeriod: noticePeriod,
    matchScore: matchScore,
    appliedAgo: appliedAgo,
    coverLetter: coverLetter,
    status: status ?? this.status,
    education: education,
    email: email,
    phone: phone,
    currentCompany: currentCompany,
    resumeName: resumeName,
    note: note ?? this.note,
    candidateId: candidateId,
  );
}

enum InterviewMode { video, phone, inPerson }

extension InterviewModeX on InterviewMode {
  String get label => switch (this) {
    InterviewMode.video => 'Video Call',
    InterviewMode.phone => 'Phone Call',
    InterviewMode.inPerson => 'In-person',
  };

  IconData get icon => switch (this) {
    InterviewMode.video => Icons.videocam_outlined,
    InterviewMode.phone => Icons.call_outlined,
    InterviewMode.inPerson => Icons.apartment_rounded,
  };
}

enum InterviewStatus { scheduled, completed, cancelled }

extension InterviewStatusX on InterviewStatus {
  String get label => switch (this) {
    InterviewStatus.scheduled => 'Scheduled',
    InterviewStatus.completed => 'Completed',
    InterviewStatus.cancelled => 'Cancelled',
  };

  Color get color => switch (this) {
    InterviewStatus.scheduled => AppColors.tintBlue,
    InterviewStatus.completed => AppColors.tintGreen,
    InterviewStatus.cancelled => AppColors.tintRed,
  };
}

class Interview {
  const Interview({
    required this.id,
    required this.applicantId,
    required this.candidateName,
    required this.jobTitle,
    required this.dateTime,
    required this.mode,
    required this.round,
    required this.interviewer,
    this.link = '',
    this.status = InterviewStatus.scheduled,
    this.candidateId = '',
  });

  final String id;
  final String applicantId;
  final String candidateName;
  final String jobTitle;
  final DateTime dateTime;
  final InterviewMode mode;
  final String round;
  final String interviewer;

  /// Meeting link, phone number or office address depending on [mode].
  final String link;
  final InterviewStatus status;

  /// The candidate's user id (for chat).
  final String candidateId;

  factory Interview.fromJson(Map<String, dynamic> j) => Interview(
    id: jStr(j['id']),
    applicantId: jStr(j['applicationId']),
    candidateId: jStr(j['candidateId']),
    candidateName: jStr(j['candidateName']),
    jobTitle: jStr(j['jobTitle']),
    dateTime: (jDate(j['dateTime']) ?? DateTime.now()).toLocal(),
    mode: InterviewMode.values.firstWhere(
      (m) => m.name == j['mode'],
      orElse: () => InterviewMode.video,
    ),
    round: jStr(j['round']),
    interviewer: jStr(j['interviewer']),
    link: jStr(j['link']),
    status: InterviewStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => InterviewStatus.scheduled,
    ),
  );

  Interview copyWith({InterviewStatus? status}) => Interview(
    id: id,
    applicantId: applicantId,
    candidateName: candidateName,
    jobTitle: jobTitle,
    dateTime: dateTime,
    mode: mode,
    round: round,
    interviewer: interviewer,
    link: link,
    status: status ?? this.status,
    candidateId: candidateId,
  );
}
