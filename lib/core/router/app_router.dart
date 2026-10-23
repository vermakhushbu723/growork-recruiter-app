import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/auth/presentation/screens/account_type_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/chat/presentation/screens/call_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/chat/presentation/screens/new_chat_screen.dart';
import '../../features/company/presentation/screens/company_form_screen.dart';
import '../../features/company/presentation/screens/company_profile_screen.dart';
import '../../features/company/presentation/screens/edit_account_screen.dart';
import '../../features/company/presentation/screens/team_members_screen.dart';
import '../../features/freelance/presentation/screens/contract_workspace_screen.dart';
import '../../features/freelance/presentation/screens/contracts_screen.dart';
import '../../features/freelance/presentation/screens/end_contract_screen.dart';
import '../../features/freelance/presentation/screens/hire_freelancer_screen.dart';
import '../../features/freelance/presentation/screens/my_projects_screen.dart';
import '../../features/freelance/presentation/screens/post_project_screen.dart';
import '../../features/freelance/presentation/screens/project_post_details_screen.dart';
import '../../features/freelance/presentation/screens/proposal_details_screen.dart';
import '../../features/freelance/presentation/screens/proposals_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/jobs/data/job_post_model.dart';
import '../../features/jobs/presentation/screens/applicant_profile_screen.dart';
import '../../features/jobs/presentation/screens/applicants_screen.dart';
import '../../features/jobs/presentation/screens/interviews_screen.dart';
import '../../features/jobs/presentation/screens/job_post_details_screen.dart';
import '../../features/jobs/presentation/screens/my_jobs_screen.dart';
import '../../features/jobs/presentation/screens/post_job_screen.dart';
import '../../features/jobs/presentation/screens/schedule_interview_screen.dart';
import '../../features/jobs/presentation/screens/send_offer_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/reviews/presentation/screens/reviews_screen.dart';
import '../../features/settings/presentation/screens/settings_pages.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/talent/presentation/screens/saved_talent_screen.dart';
import '../../features/talent/presentation/screens/talent_profile_screen.dart';
import '../../features/talent/presentation/screens/talent_search_screen.dart';
import '../../features/wallet/presentation/screens/plans_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/wallet/presentation/screens/wallet_transfer_screen.dart';
import '../../shared/navigation/main_shell.dart';
import 'route_paths.dart';

/// Shorthand for a top-level route whose screen takes the id in `extra`.
GoRoute _idRoute(String path, Widget Function(String id) build) => GoRoute(
  path: path,
  builder: (context, state) => build(state.extra as String? ?? ''),
);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth & onboarding ───────────────────────────────────
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.otpVerification,
        builder: (context, state) => OtpVerificationScreen(
          args: state.extra as OtpArgs? ?? const OtpArgs(),
        ),
      ),
      GoRoute(
        path: RoutePaths.accountType,
        builder: (context, state) =>
            AccountTypeScreen(fromSettings: state.extra == true),
      ),
      GoRoute(
        path: RoutePaths.companySetup,
        builder: (context, state) => const CompanyFormScreen(onboarding: true),
      ),

      // ── Jobs & hiring ───────────────────────────────────────
      GoRoute(
        path: RoutePaths.postJob,
        builder: (context, state) =>
            PostJobScreen(jobId: state.extra as String?),
      ),
      _idRoute(RoutePaths.jobDetails, (id) => JobPostDetailsScreen(jobId: id)),
      GoRoute(
        path: RoutePaths.applicants,
        builder: (context, state) => ApplicantsScreen(
          args: switch (state.extra) {
            final ApplicantsArgs a => a,
            final String jobId => ApplicantsArgs(jobId: jobId),
            final ApplicantStatus s => ApplicantsArgs(status: s),
            _ => const ApplicantsArgs(),
          },
        ),
      ),
      _idRoute(
        RoutePaths.applicantProfile,
        (id) => ApplicantProfileScreen(applicantId: id),
      ),
      _idRoute(
        RoutePaths.scheduleInterview,
        (id) => ScheduleInterviewScreen(applicantId: id),
      ),
      GoRoute(
        path: RoutePaths.interviews,
        builder: (context, state) => const InterviewsScreen(),
      ),
      _idRoute(RoutePaths.sendOffer, (id) => SendOfferScreen(applicantId: id)),

      // ── Freelance projects ──────────────────────────────────
      GoRoute(
        path: RoutePaths.postProject,
        builder: (context, state) =>
            PostProjectScreen(projectId: state.extra as String?),
      ),
      _idRoute(
        RoutePaths.projectDetails,
        (id) => ProjectPostDetailsScreen(projectId: id),
      ),
      _idRoute(RoutePaths.proposals, (id) => ProposalsScreen(projectId: id)),
      _idRoute(
        RoutePaths.proposalDetails,
        (id) => ProposalDetailsScreen(proposalId: id),
      ),
      _idRoute(
        RoutePaths.hireFreelancer,
        (id) => HireFreelancerScreen(proposalId: id),
      ),
      GoRoute(
        path: RoutePaths.contracts,
        builder: (context, state) => const ContractsScreen(),
      ),
      _idRoute(
        RoutePaths.contract,
        (id) => ContractWorkspaceScreen(contractId: id),
      ),
      _idRoute(
        RoutePaths.endContract,
        (id) => EndContractScreen(contractId: id),
      ),

      // ── Talent ──────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.talentSearch,
        builder: (context, state) => const TalentSearchScreen(),
      ),
      _idRoute(
        RoutePaths.talentProfile,
        (id) => TalentProfileScreen(talentId: id),
      ),
      GoRoute(
        path: RoutePaths.savedTalent,
        builder: (context, state) => const SavedTalentScreen(),
      ),

      // ── Chat ────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.chatRoom,
        builder: (context, state) => ChatRoomScreen(
          target: state.extra as ChatTarget? ?? const ChatTarget(name: 'Chat'),
        ),
      ),
      GoRoute(
        path: RoutePaths.newChat,
        builder: (context, state) => const NewChatScreen(),
      ),
      GoRoute(
        path: RoutePaths.call,
        builder: (context, state) => CallScreen(
          args: state.extra as CallArgs? ?? const CallArgs(name: 'Contact'),
        ),
      ),

      // ── Account ─────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: RoutePaths.addMoney,
        builder: (context, state) =>
            const WalletTransferScreen(withdraw: false),
      ),
      GoRoute(
        path: RoutePaths.withdraw,
        builder: (context, state) => const WalletTransferScreen(withdraw: true),
      ),
      GoRoute(
        path: RoutePaths.plans,
        builder: (context, state) => const PlansScreen(),
      ),
      GoRoute(
        path: RoutePaths.editCompany,
        builder: (context, state) => const CompanyFormScreen(),
      ),
      GoRoute(
        path: RoutePaths.editProfile,
        builder: (context, state) => const EditAccountScreen(),
      ),
      GoRoute(
        path: RoutePaths.team,
        builder: (context, state) => const TeamMembersScreen(),
      ),
      GoRoute(
        path: RoutePaths.analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: RoutePaths.reviews,
        builder: (context, state) => const ReviewsScreen(),
      ),

      // ── Settings ────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.language,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: RoutePaths.privacy,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: RoutePaths.help,
        builder: (context, state) => const HelpScreen(),
      ),

      // ── Bottom navigation shell ─────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.jobs,
                builder: (context, state) => const MyJobsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.projects,
                builder: (context, state) => const MyProjectsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.chat,
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const CompanyProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
