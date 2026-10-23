/// What the recruiter uses the app for. Decides which modules are shown
/// first, but every account can both post jobs and post freelance projects.
enum AccountType { recruiter, client, both }

extension AccountTypeX on AccountType {
  String get label => switch (this) {
    AccountType.recruiter => 'Recruiter',
    AccountType.client => 'Freelance Client',
    AccountType.both => 'Recruiter & Client',
  };

  String get description => switch (this) {
    AccountType.recruiter => 'Post jobs & internships and hire employees',
    AccountType.client => 'Post freelance projects and hire freelancers',
    AccountType.both => 'Hire full-time staff and freelancers together',
  };
}
