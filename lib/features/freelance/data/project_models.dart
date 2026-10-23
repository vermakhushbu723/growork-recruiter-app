import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

enum PricingType { fixed, hourly }

extension PricingTypeX on PricingType {
  String get label => this == PricingType.fixed ? 'Fixed Price' : 'Hourly Rate';
}

/// Category filters, same set as the user app's Freelance tab.
const List<({String label, String category})> projectCategories = [
  (label: 'Web Dev', category: 'Web Development'),
  (label: 'Design', category: 'Design'),
  (label: 'Mobile Dev', category: 'Mobile Development'),
  (label: 'Writing', category: 'Content Writing'),
  (label: 'Marketing', category: 'Digital Marketing'),
  (label: 'Backend', category: 'Backend Development'),
];

const List<String> projectDurations = [
  'Less than 1 week',
  '1–2 weeks',
  '2–4 weeks',
  '1–3 months',
  '3+ months',
];

const List<String> freelancerLevels = ['Entry', 'Intermediate', 'Expert'];

Color projectCategoryColor(String category) => switch (category) {
  'Web Development' => AppColors.tintBlue,
  'Design' => AppColors.tintRed,
  'Mobile Development' => AppColors.tintGreen,
  'Content Writing' => AppColors.tintOrange,
  'Digital Marketing' => AppColors.tintPurple,
  _ => AppColors.tintTeal,
};

IconData projectCategoryIcon(String category) => switch (category) {
  'Web Development' => Icons.laptop_rounded,
  'Design' => Icons.palette_rounded,
  'Mobile Development' => Icons.smartphone_rounded,
  'Content Writing' => Icons.edit_rounded,
  'Digital Marketing' => Icons.campaign_rounded,
  _ => Icons.dns_rounded,
};

PricingType _pricing(Object? v) =>
    v == 'hourly' ? PricingType.hourly : PricingType.fixed;

enum ProjectStatus { open, inProgress, completed, draft, closed }

extension ProjectStatusX on ProjectStatus {
  String get label => switch (this) {
    ProjectStatus.open => 'Open',
    ProjectStatus.inProgress => 'In Progress',
    ProjectStatus.completed => 'Completed',
    ProjectStatus.draft => 'Draft',
    ProjectStatus.closed => 'Closed',
  };

  Color get color => switch (this) {
    ProjectStatus.open => AppColors.tintGreen,
    ProjectStatus.inProgress => AppColors.tintBlue,
    ProjectStatus.completed => AppColors.tintPurple,
    ProjectStatus.draft => AppColors.textSub,
    ProjectStatus.closed => AppColors.tintRed,
  };
}

class ProjectPost {
  const ProjectPost({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.skills,
    required this.pricing,
    required this.budgetMin,
    required this.budgetMax,
    required this.duration,
    required this.level,
    this.status = ProjectStatus.open,
    this.postedAgo = 'Just now',
    this.views = 0,
    this.attachments = const [],
    this.hiredFreelancer,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final List<String> skills;
  final PricingType pricing;

  /// Whole-project budget for fixed price, rate per hour for hourly.
  final int budgetMin;
  final int budgetMax;
  final String duration;
  final String level;
  final ProjectStatus status;
  final String postedAgo;
  final int views;
  final List<String> attachments;
  final String? hiredFreelancer;

  factory ProjectPost.fromJson(Map<String, dynamic> j) {
    final status = ProjectStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => ProjectStatus.open,
    );
    return ProjectPost(
      id: jStr(j['id']),
      title: jStr(j['title']),
      category: jStr(j['category']),
      description: jStr(j['description']),
      skills: jStrList(j['skills']),
      pricing: _pricing(j['pricing']),
      budgetMin: jInt(j['budgetMin']),
      budgetMax: jInt(j['budgetMax']),
      duration: jStr(j['duration']),
      level: jStr(j['level'], 'Intermediate'),
      status: status,
      postedAgo: status == ProjectStatus.draft
          ? 'Not posted'
          : timeAgo(jDate(j['publishedAt']) ?? jDate(j['createdAt'])),
      views: jInt(j['views']),
      attachments: jStrList(j['attachments']),
      hiredFreelancer: jMap(j['hiredFreelancer'])['name'] as String?,
    );
  }

  /// Body for `POST /client/projects` and `PATCH /client/projects/:id`.
  Map<String, dynamic> toJson({String visibility = 'Public'}) => {
    'title': title,
    'category': category,
    'description': description,
    'skills': skills,
    'pricing': pricing.name,
    'budgetMin': budgetMin,
    'budgetMax': budgetMax,
    'duration': duration,
    'level': level,
    'visibility': visibility,
    'status': status.name,
    'attachments': attachments,
  };

  String get budgetLabel => pricing == PricingType.fixed
      ? '${formatRupees(budgetMin)} - ${formatRupees(budgetMax)}'
      : '${formatRupees(budgetMin)} - ${formatRupees(budgetMax)} /hr';

  ProjectPost copyWith({
    String? title,
    String? category,
    String? description,
    List<String>? skills,
    PricingType? pricing,
    int? budgetMin,
    int? budgetMax,
    String? duration,
    String? level,
    ProjectStatus? status,
    String? postedAgo,
    List<String>? attachments,
    String? hiredFreelancer,
  }) {
    return ProjectPost(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      pricing: pricing ?? this.pricing,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      duration: duration ?? this.duration,
      level: level ?? this.level,
      status: status ?? this.status,
      postedAgo: postedAgo ?? this.postedAgo,
      views: views,
      attachments: attachments ?? this.attachments,
      hiredFreelancer: hiredFreelancer ?? this.hiredFreelancer,
    );
  }
}

/// ₹ with Indian digit grouping: 125000 → ₹1,25,000.
String formatRupees(int value) {
  final s = value.abs().toString();
  String grouped;
  if (s.length <= 3) {
    grouped = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${value < 0 ? '-' : ''}₹$grouped';
}

enum ProposalStatus { received, shortlisted, hired, declined }

extension ProposalStatusX on ProposalStatus {
  String get label => switch (this) {
    ProposalStatus.received => 'New',
    ProposalStatus.shortlisted => 'Shortlisted',
    ProposalStatus.hired => 'Hired',
    ProposalStatus.declined => 'Declined',
  };

  Color get color => switch (this) {
    ProposalStatus.received => AppColors.tintBlue,
    ProposalStatus.shortlisted => AppColors.tintOrange,
    ProposalStatus.hired => AppColors.tintGreen,
    ProposalStatus.declined => AppColors.tintRed,
  };
}

class Proposal {
  const Proposal({
    required this.id,
    required this.projectId,
    required this.freelancer,
    required this.headline,
    required this.location,
    required this.rating,
    required this.jobsDone,
    required this.successRate,
    required this.pricing,
    required this.amount,
    required this.deliveryDays,
    required this.coverLetter,
    required this.skills,
    required this.submittedAgo,
    this.status = ProposalStatus.received,
    this.isTopRated = false,
    this.freelancerId = '',
  });

  final String id;
  final String projectId;
  final String freelancer;
  final String headline;
  final String location;
  final double rating;
  final int jobsDone;

  /// Percentage of past jobs completed successfully.
  final int successRate;
  final PricingType pricing;

  /// Total bid for fixed price, rate per hour for hourly.
  final int amount;
  final int deliveryDays;
  final String coverLetter;
  final List<String> skills;
  final String submittedAgo;
  final ProposalStatus status;
  final bool isTopRated;

  /// The freelancer's user id (for chat and their talent profile).
  final String freelancerId;

  factory Proposal.fromJson(Map<String, dynamic> j) {
    final f = jMap(j['freelancer']);
    final status = switch (j['status']) {
      'shortlisted' || 'interview' => ProposalStatus.shortlisted,
      'hired' => ProposalStatus.hired,
      'declined' => ProposalStatus.declined,
      _ => ProposalStatus.received,
    };
    final rating = jDouble(f['rating']);
    return Proposal(
      id: jStr(j['id']),
      projectId: jStr(j['projectId']),
      freelancerId: jStr(f['id']),
      freelancer: jStr(f['name'], 'Freelancer'),
      headline: jStr(f['headline']),
      location: jStr(f['location']),
      rating: rating,
      jobsDone: jInt(f['jobsDone']),
      successRate: jInt(f['successRate']),
      pricing: _pricing(j['pricing']),
      amount: jInt(j['amount']),
      deliveryDays: jInt(j['deliveryDays'], 7),
      coverLetter: jStr(j['coverLetter']),
      skills: jStrList(f['skills']),
      submittedAgo: timeAgo(jDate(j['createdAt'])),
      status: status,
      isTopRated: rating >= 4.8 && jInt(f['jobsDone']) >= 20,
    );
  }

  String get bidLabel => pricing == PricingType.fixed
      ? formatRupees(amount)
      : '${formatRupees(amount)} /hr';

  Proposal copyWith({ProposalStatus? status}) => Proposal(
    id: id,
    projectId: projectId,
    freelancer: freelancer,
    headline: headline,
    location: location,
    rating: rating,
    jobsDone: jobsDone,
    successRate: successRate,
    pricing: pricing,
    amount: amount,
    deliveryDays: deliveryDays,
    coverLetter: coverLetter,
    skills: skills,
    submittedAgo: submittedAgo,
    status: status ?? this.status,
    isTopRated: isTopRated,
    freelancerId: freelancerId,
  );
}

/// Client-side milestone money flow: client funds a milestone into escrow →
/// freelancer submits work → client releases payment or requests changes.
enum MilestoneStatus { notFunded, funded, submitted, revision, released }

extension MilestoneStatusX on MilestoneStatus {
  String get label => switch (this) {
    MilestoneStatus.notFunded => 'Not funded',
    MilestoneStatus.funded => 'Funded · In progress',
    MilestoneStatus.submitted => 'Awaiting your review',
    MilestoneStatus.revision => 'Revision requested',
    MilestoneStatus.released => 'Paid',
  };

  Color get color => switch (this) {
    MilestoneStatus.notFunded => AppColors.textSub,
    MilestoneStatus.funded => AppColors.tintBlue,
    MilestoneStatus.submitted => AppColors.tintOrange,
    MilestoneStatus.revision => AppColors.tintRed,
    MilestoneStatus.released => AppColors.tintGreen,
  };
}

class Milestone {
  const Milestone({
    required this.title,
    required this.amount,
    required this.dueIn,
    this.status = MilestoneStatus.notFunded,
    this.note,
  });

  final String title;
  final int amount;
  final String dueIn;
  final MilestoneStatus status;

  /// Freelancer's delivery note, or the client's revision request.
  final String? note;

  factory Milestone.fromJson(Map<String, dynamic> j) {
    final note = jStr(j['note']);
    return Milestone(
      title: jStr(j['title']),
      amount: jInt(j['amount']),
      dueIn: jStr(j['dueIn']),
      status: MilestoneStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => MilestoneStatus.notFunded,
      ),
      note: note.isEmpty ? null : note,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'dueIn': dueIn,
  };

  Milestone copyWith({MilestoneStatus? status, String? note, String? dueIn}) =>
      Milestone(
        title: title,
        amount: amount,
        dueIn: dueIn ?? this.dueIn,
        status: status ?? this.status,
        note: note ?? this.note,
      );
}

enum ContractStatus { active, completed }

class ContractModel {
  const ContractModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.freelancer,
    required this.startedOn,
    required this.milestones,
    this.status = ContractStatus.active,
    this.pricing = PricingType.fixed,
    this.rating,
    this.review,
    this.freelancerId = '',
  });

  final String id;
  final String projectId;
  final String title;
  final String freelancer;
  final String startedOn;
  final List<Milestone> milestones;
  final ContractStatus status;
  final PricingType pricing;

  /// Feedback the client left when ending the contract.
  final double? rating;
  final String? review;

  /// The freelancer's user id (for chat).
  final String freelancerId;

  factory ContractModel.fromJson(Map<String, dynamic> j) {
    final started = jDate(j['startedOn']);
    return ContractModel(
      id: jStr(j['id']),
      projectId: jStr(j['projectId']),
      title: jStr(j['title']),
      freelancer: jStr(jMap(j['freelancer'])['name'], 'Freelancer'),
      freelancerId: jStr(jMap(j['freelancer'])['id']),
      startedOn: started == null
          ? ''
          : '${started.day.toString().padLeft(2, '0')} ${_months[started.month - 1]} ${started.year}',
      milestones: jMapList(j['milestones']).map(Milestone.fromJson).toList(),
      status: j['status'] == 'completed'
          ? ContractStatus.completed
          : ContractStatus.active,
      pricing: _pricing(j['pricing']),
      rating: j['rating'] == null ? null : jDouble(j['rating']),
      review: j['review'] as String?,
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  int get total => milestones.fold(0, (sum, m) => sum + m.amount);

  int get released => milestones
      .where((m) => m.status == MilestoneStatus.released)
      .fold(0, (sum, m) => sum + m.amount);

  int get inEscrow => milestones
      .where(
        (m) =>
            m.status == MilestoneStatus.funded ||
            m.status == MilestoneStatus.submitted ||
            m.status == MilestoneStatus.revision,
      )
      .fold(0, (sum, m) => sum + m.amount);

  double get progress => total == 0 ? 0 : released / total;

  bool get awaitingReview =>
      milestones.any((m) => m.status == MilestoneStatus.submitted);

  ContractModel copyWith({
    List<Milestone>? milestones,
    ContractStatus? status,
    double? rating,
    String? review,
  }) => ContractModel(
    id: id,
    projectId: projectId,
    title: title,
    freelancer: freelancer,
    startedOn: startedOn,
    milestones: milestones ?? this.milestones,
    status: status ?? this.status,
    pricing: pricing,
    rating: rating ?? this.rating,
    review: review ?? this.review,
    freelancerId: freelancerId,
  );
}
