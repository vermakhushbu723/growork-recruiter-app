import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/banners.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/project_models.dart';
import '../../providers/client_projects_provider.dart';
import '../widgets/project_post_card.dart';

/// Projects tab: freelance projects the client posted.
class MyProjectsScreen extends ConsumerStatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  ConsumerState<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends ConsumerState<MyProjectsScreen> {
  String _query = '';
  ProjectStatus? _status;
  String? _category;
  String _sort = 'Latest';

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientProjectsProvider);
    final projects = client.projects.where((p) {
      if (_status != null && p.status != _status) return false;
      if (_category != null && p.category != _category) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.skills.any((s) => s.toLowerCase().contains(q));
    }).toList();
    if (_sort == 'Most proposals') {
      projects.sort(
        (a, b) => client
            .proposalsFor(b.id)
            .length
            .compareTo(client.proposalsFor(a.id).length),
      );
    } else if (_sort == 'Budget') {
      projects.sort((a, b) => b.budgetMax.compareTo(a.budgetMax));
    }

    return Scaffold(
      backgroundColor: context.isDark ? null : const Color(0xFFFFF6F9),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'post_project_fab',
        onPressed: () => context.push(RoutePaths.postProject),
        backgroundColor: kButtonBlue,
        foregroundColor: Colors.white,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(
          'Post Project',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 14, 0),
                child: PageHeader(
                  title: 'My Projects',
                  subtitle:
                      '${client.activeContracts.length} active contracts · ${client.proposals.length} proposals received',
                  subtitleSize: 9.5,
                  trailing: HeaderActionButton(
                    icon: Icons.handshake_outlined,
                    label: 'Contracts',
                    onTap: () => context.push(RoutePaths.contracts),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 14, 8),
                child: SearchFilterBar(
                  hint: 'Search your projects by title or skill...',
                  height: 38,
                  bordered: true,
                  solidFilter: true,
                  showFilterDot: _category != null,
                  onChanged: (v) => setState(() => _query = v),
                  onFilter: () => _showCategorySheet(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ChipScroller(
                padding: 15,
                children: [
                  PillChip(
                    label: 'All (${client.projects.length})',
                    selected: _status == null,
                    onTap: () => setState(() => _status = null),
                  ),
                  for (final s in ProjectStatus.values)
                    PillChip(
                      label:
                          '${s.label} (${client.projects.where((p) => p.status == s).length})',
                      color: s.color,
                      selected: _status == s,
                      onTap: () => setState(() => _status = s),
                    ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 14, 0),
                child: PromoBanner(
                  title: 'Hire Top Freelancers',
                  message:
                      'Invite verified freelancers to your project and pay safely by milestone',
                  ctaLabel: 'Find Freelancers',
                  icon: Icons.person_search_rounded,
                  points: const [
                    'Verified profiles',
                    'Escrow protection',
                    'Pay per milestone',
                  ],
                  onTap: () => context.push(RoutePaths.talentSearch),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 12, 8),
                child: SectionTitle(
                  _category ?? 'Your Projects',
                  trailing: SortByButton(
                    value: _sort,
                    onTap: () => _showSortSheet(context),
                  ),
                ),
              ),
            ),
            if (projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.laptop_mac_outlined,
                  title: 'No projects here',
                  message: 'Post a project and freelancers will send proposals',
                  actionLabel: 'Post a Project',
                  onAction: () => context.push(RoutePaths.postProject),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 14, 80),
                sliver: SliverList.separated(
                  itemCount: projects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = projects[index];
                    final proposals = client.proposalsFor(p.id);
                    return ProjectPostCard(
                      project: p,
                      proposals: proposals.length,
                      newProposals: proposals
                          .where((x) => x.status == ProposalStatus.received)
                          .length,
                      onTap: () =>
                          context.push(RoutePaths.projectDetails, extra: p.id),
                      onProposals: p.hiredFreelancer != null
                          ? null
                          : () =>
                                context.push(RoutePaths.proposals, extra: p.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Sort projects by',
        children: [
          for (final o in const [
            (Icons.schedule_rounded, 'Latest'),
            (Icons.people_outline_rounded, 'Most proposals'),
            (Icons.payments_outlined, 'Budget'),
          ])
            SheetOption(
              icon: o.$1,
              label: o.$2,
              selected: _sort == o.$2,
              onTap: () {
                setState(() => _sort = o.$2);
                Navigator.pop(sheetContext);
              },
            ),
        ],
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
        child: SheetBody(
          title: 'Filter by category',
          children: [
            SheetOption(
              icon: Icons.all_inclusive_rounded,
              label: 'All categories',
              selected: _category == null,
              onTap: () {
                setState(() => _category = null);
                Navigator.pop(sheetContext);
              },
            ),
            for (final c in projectCategories)
              SheetOption(
                icon: projectCategoryIcon(c.category),
                label: c.category,
                selected: _category == c.category,
                onTap: () {
                  setState(() => _category = c.category);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }
}
