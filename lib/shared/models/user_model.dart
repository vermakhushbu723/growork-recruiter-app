import '../../core/network/api_client.dart';
import 'account_type.dart';

/// Signed-in recruiter / client and the company they hire for.
class RecruiterUser {
  const RecruiterUser({
    required this.id,
    required this.name,
    required this.email,
    required this.accountType,
    this.phone = '',
    this.designation = '',
    this.company = const CompanyModel(),
    this.profileCompletion = 0,
  });

  final String id;
  final String name;
  final String email;
  final AccountType accountType;
  final String phone;
  final String designation;
  final CompanyModel company;
  final double profileCompletion;

  factory RecruiterUser.fromJson(Map<String, dynamic> j) {
    final company = j['company'];
    return RecruiterUser(
      id: jStr(j['id']),
      name: jStr(j['name']),
      email: jStr(j['email']),
      accountType: AccountType.values.firstWhere(
        (t) => t.name == j['accountType'],
        orElse: () => AccountType.both,
      ),
      phone: jStr(j['phone']),
      designation: jStr(j['designation']),
      company: company is Map
          ? CompanyModel.fromJson(Map<String, dynamic>.from(company))
          : const CompanyModel(),
      profileCompletion: jDouble(j['profileCompletion']),
    );
  }

  RecruiterUser copyWith({
    String? name,
    String? email,
    AccountType? accountType,
    String? phone,
    String? designation,
    CompanyModel? company,
    double? profileCompletion,
  }) {
    return RecruiterUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      accountType: accountType ?? this.accountType,
      phone: phone ?? this.phone,
      designation: designation ?? this.designation,
      company: company ?? this.company,
      profileCompletion: profileCompletion ?? this.profileCompletion,
    );
  }
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.pending = false,
    this.isOwner = false,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool pending;
  final bool isOwner;
}

class CompanyModel {
  const CompanyModel({
    this.id = '',
    this.name = '',
    this.industry = 'Information Technology',
    this.size = '1-10 employees',
    this.website = '',
    this.location = '',
    this.about = '',
    this.founded = '',
    this.gstin = '',
    this.isVerified = false,
    this.pageViews = 0,
    this.members = const [],
  });

  final String id;
  final String name;
  final String industry;
  final String size;
  final String website;
  final String location;
  final String about;
  final String founded;
  final String gstin;
  final bool isVerified;
  final int pageViews;
  final List<TeamMember> members;

  factory CompanyModel.fromJson(Map<String, dynamic> j) {
    final owner = jStr(j['owner']);
    return CompanyModel(
      id: jStr(j['id']),
      name: jStr(j['name']),
      industry: jStr(j['industry']),
      size: jStr(j['size']),
      website: jStr(j['website']),
      location: jStr(j['location']),
      about: jStr(j['about']),
      founded: jStr(j['founded']),
      gstin: jStr(j['gstin']),
      isVerified: jBool(j['isVerified']),
      pageViews: jInt(j['pageViews']),
      members: [
        for (final m in jMapList(j['members']))
          TeamMember(
            id: jStr(m['id']),
            name: jStr(m['name']),
            email: jStr(m['email']),
            role: jStr(m['role'], 'Recruiter'),
            pending: jBool(m['pending']),
            isOwner: owner.isNotEmpty && jStr(m['user']) == owner,
          ),
      ],
    );
  }

  /// Body for `PATCH /company`.
  Map<String, dynamic> toJson() => {
    'name': name,
    'industry': industry,
    'size': size,
    'website': website,
    'location': location,
    'about': about,
    'founded': founded,
    'gstin': gstin,
  };

  CompanyModel copyWith({
    String? name,
    String? industry,
    String? size,
    String? website,
    String? location,
    String? about,
    String? founded,
    String? gstin,
  }) {
    return CompanyModel(
      id: id,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      size: size ?? this.size,
      website: website ?? this.website,
      location: location ?? this.location,
      about: about ?? this.about,
      founded: founded ?? this.founded,
      gstin: gstin ?? this.gstin,
      isVerified: isVerified,
      pageViews: pageViews,
      members: members,
    );
  }
}
