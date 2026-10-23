import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/talent_model.dart';
import '../widgets/talent_card.dart';

/// Candidates and freelancers the recruiter bookmarked.
class SavedTalentScreen extends ConsumerStatefulWidget {
  const SavedTalentScreen({super.key});

  @override
  ConsumerState<SavedTalentScreen> createState() => _SavedTalentScreenState();
}

class _SavedTalentScreenState extends ConsumerState<SavedTalentScreen> {
  TalentKind? _kind;

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedTalentProvider).items;
    final list = saved.where((t) => _kind == null || t.kind == _kind).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Talent')),
      body: saved.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Nothing saved yet',
              message: 'Bookmark candidates and freelancers to find them later',
              actionLabel: 'Find Talent',
              onAction: () => context.push(RoutePaths.talentSearch),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
              children: [
                Row(
                  children: [
                    for (final o in [
                      (null, 'All (${saved.length})'),
                      (TalentKind.candidate, 'Job Seekers'),
                      (TalentKind.freelancer, 'Freelancers'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: PillChip(
                          label: o.$2,
                          height: 22,
                          selected: _kind == o.$1,
                          onTap: () => setState(() => _kind = o.$1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final t in list) ...[
                  TalentCard(
                    talent: t,
                    onTap: () =>
                        context.push(RoutePaths.talentProfile, extra: t.id),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}
