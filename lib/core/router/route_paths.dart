class RoutePaths {
  RoutePaths._();

  static const String splash = '/splash';

  // Auth & onboarding
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String accountType = '/account-type';
  static const String companySetup = '/company-setup';

  // Bottom-nav shell tabs
  static const String home = '/home';
  static const String jobs = '/jobs';
  static const String projects = '/projects';
  static const String chat = '/chat';
  static const String profile = '/profile';

  // Jobs & hiring (pushed with an id in `extra`)
  static const String postJob = '/jobs/post';
  static const String jobDetails = '/jobs/details';
  static const String applicants = '/jobs/applicants';
  static const String applicantProfile = '/applicant';
  static const String scheduleInterview = '/interviews/schedule';
  static const String interviews = '/interviews';
  static const String sendOffer = '/offer';

  // Freelance projects (client side)
  static const String postProject = '/projects/post';
  static const String projectDetails = '/projects/details';
  static const String proposals = '/projects/proposals';
  static const String proposalDetails = '/proposal';
  static const String hireFreelancer = '/hire';
  static const String contracts = '/contracts';
  static const String contract = '/contract';
  static const String endContract = '/contract/end';

  // Talent search
  static const String talentSearch = '/talent';
  static const String talentProfile = '/talent/profile';
  static const String savedTalent = '/talent/saved';

  // Chat
  static const String chatRoom = '/chat-room';
  static const String newChat = '/chat-new';
  static const String call = '/call';

  // Account
  static const String notifications = '/notifications';
  static const String wallet = '/wallet';
  static const String addMoney = '/wallet/add-money';
  static const String withdraw = '/wallet/withdraw';
  static const String plans = '/plans';
  static const String editCompany = '/profile/company';
  static const String editProfile = '/profile/edit';
  static const String team = '/profile/team';
  static const String analytics = '/analytics';
  static const String reviews = '/reviews';

  // Settings
  static const String settings = '/settings';
  static const String language = '/settings/language';
  static const String privacy = '/settings/privacy';
  static const String help = '/help';
}
