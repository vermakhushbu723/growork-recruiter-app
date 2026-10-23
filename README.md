# Subkamyaab Recruiter App

Recruiter / client side of Subkamyaab: post jobs & internships, hire freelancers,
and manage the whole hiring flow. Built on the same design system as
`growork-user-app` — `lib/core` (colours, theme, sizes, `ui_kit.dart`) is a copy
of the user app's, so screens look identical across both apps.

Runs on mock data (Riverpod providers) until the backend is wired in.

## Screens

| Area | Screens |
|---|---|
| Auth & onboarding | Splash, Login, Signup, Forgot password, OTP, Hiring type, Company setup |
| Home (tab) | Dashboard — hiring overview, quick actions, needs-attention, new applicants, active jobs |
| Jobs (tab) | My job posts, Post / edit job (4 steps), Job post details, Applicants pipeline, Candidate profile, Schedule interview, Interviews, Send offer |
| Projects (tab) | My projects, Post / edit project (3 steps), Project details, Proposals, Proposal details, Hire freelancer (milestones + escrow), Contracts, Contract workspace, End contract & review |
| Talent | Find talent, Talent profile, Saved talent |
| Chat (tab) | Chat list, Chat room, New chat, Voice/video call |
| Profile (tab) | Company profile, Edit company, My account, Team members |
| Money | Wallet & payments, Add money, Withdraw, Plans & credits |
| Other | Hiring analytics, Reviews, Notifications, Settings, Language, Privacy, Help |

## Flows that work end to end (mock)

- Publish a job → uses a job credit → appears in Jobs; edit, pause, close, duplicate, delete.
- Applicant → Shortlist → Schedule interview → Send offer → Mark hired (or reject).
- Post a project → review proposals → Hire (first milestone funded from wallet into escrow)
  → approve & release / request changes → end contract with a review (unused escrow refunded).

## Run

```
flutter pub get
flutter run
flutter test   # includes a test that renders every screen in light & dark
```

Log in with any email/password (mock auth).
