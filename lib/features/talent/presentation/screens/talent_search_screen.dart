import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/talent_model.dart';
import '../widgets/talent_card.dart';

const _popularSkills = [
  'Flutter',
  'React',
  'Node.js',
  'Figma',
  'SEO',
  'Branding',
  'Python',
];

/// Search the talent pool: job seekers and freelancers.
class TalentSearchScreen extends ConsumerStatefulWidget {
  const TalentSearchScreen({super.key});

  @override
  ConsumerState<TalentSearchScreen> createState() => _TalentSearchScreenState();
}

class _TalentSearchScreenState extends ConsumerState<TalentSearchScreen> {
  final _search = TextEditingController();
  String _query = '';
  TalentKind? _kind;
  bool _availableOnly = false;
  String _sort = 'Top rated';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final async = ref.watch(talentListProvider);
    final list = (async.value ?? const <TalentModel>[]).where((t) {
      if (_kind != null && t.kind != _kind) return false;
      if (_availableOnly && !t.available) return false;
      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) ||
          t.headline.toLowerCase().contains(q) ||
          t.location.toLowerCase().contains(q) ||
          t.skills.any((s) => s.toLowerCase().contains(q));
    }).toList();
    if (_sort == 'Top rated') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sort == 'Most experienced') {
      list.sort((a, b) => b.jobsDone.compareTo(a.jobsDone));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Talent'),
        actions: [
          IconButton(
            tooltip: 'Saved talent',
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () => context.push(RoutePaths.savedTalent),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 2, 12, 10),
              child: SearchFilterBar(
                height: 36,
                fontSize: 9.5,
                hint: 'Search by skill, role, name or city...',
                controller: _search,
                solidFilter: true,
                showFilterDot: _availableOnly,
                onChanged: (v) => setState(() => _query = v),
                onFilter: () => _showFilterSheet(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ChipScroller(
              children: [
                PillChip(
                  label: 'All',
                  selected: _kind == null,
                  onTap: () => setState(() => _kind = null),
                ),
                PillChip(
                  label: 'Job Seekers',
                  icon: Icons.work_outline_rounded,
                  selected: _kind == TalentKind.candidate,
                  onTap: () => setState(() => _kind = TalentKind.candidate),
                ),
                PillChip(
                  label: 'Freelancers',
                  icon: Icons.laptop_mac_rounded,
                  selected: _kind == TalentKind.freelancer,
                  onTap: () => setState(() => _kind = TalentKind.freelancer),
                ),
                PillChip(
                  label: 'Available now',
                  icon: Icons.circle,
                  selected: _availableOnly,
                  onTap: () => setState(() => _availableOnly = !_availableOnly),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ChipScroller(
                children: [
                  for (final s in _popularSkills)
                    PillChip(
                      label: s,
                      height: 20,
                      color: AppColors.tintPurple,
                      selected: _query.toLowerCase() == s.toLowerCase(),
                      onTap: () => setState(() {
                        _query = _query == s ? '' : s;
                        _search.text = _query;
                      }),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 10, 6),
              child: SectionTitle(
                '${list.length} profiles found',
                trailing: SortByButton(
                  value: _sort,
                  onTap: () => _showSortSheet(context),
                ),
              ),
            ),
          ),
          if (async.isLoading && !async.hasValue)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (async.hasError && !async.hasValue)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Couldn’t load profiles',
                message: async.error.toString(),
                actionLabel: 'Try again',
                onAction: () => ref.invalidate(talentListProvider),
              ),
            )
          else if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.person_search_outlined,
                title: 'No matching profiles',
                message: 'Try another skill or remove filters',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 20),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => TalentCard(
                  talent: list[i],
                  onTap: () =>
                      context.push(RoutePaths.talentProfile, extra: list[i].id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SheetBody(
        title: 'Sort profiles by',
        children: [
          for (final o in const [
            (Icons.star_border_rounded, 'Top rated'),
            (Icons.task_alt_rounded, 'Most experienced'),
            (Icons.auto_awesome_outlined, 'Relevance'),
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

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SheetBody(
          title: 'Filter talent',
          children: [
            MenuTile(
              icon: Icons.bolt_rounded,
              title: 'Available now',
              subtitle: 'Open to work or taking projects',
              onTap: () {
                setState(() => _availableOnly = !_availableOnly);
                setSheet(() {});
              },
              trailing: Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _availableOnly,
                  onChanged: (v) {
                    setState(() => _availableOnly = v);
                    setSheet(() {});
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Show Results'),
            ),
          ],
        ),
      ),
    );
  }
}
