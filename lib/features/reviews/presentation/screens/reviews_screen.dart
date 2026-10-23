import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/providers/auth_provider.dart';

class _Review {
  const _Review({
    required this.name,
    required this.rating,
    required this.comment,
    required this.context,
    required this.date,
  });
  final String name;
  final double rating;
  final String comment;
  final String context;
  final String date;
}

class _Summary {
  const _Summary(this.average, this.count, this.breakdown, this.items);
  final double average;
  final int count;

  /// (stars, share of reviews 0–1), 5 → 1.
  final List<(int, double)> breakdown;
  final List<_Review> items;
}

final _reviewsProvider = FutureProvider.autoDispose<_Summary>((ref) async {
  ref.watch(sessionUserIdProvider);
  final d = jMap(await api.get('/reviews/me'));
  final count = jInt(d['count']);
  return _Summary(
    jDouble(d['average']),
    count,
    [
      for (final b in jMapList(d['breakdown']))
        (jInt(b['star']), count == 0 ? 0.0 : jInt(b['count']) / count),
    ],
    [
      for (final r in jMapList(d['items']))
        _Review(
          name: jStr(r['name'], 'User'),
          rating: jDouble(r['rating']),
          comment: jStr(r['comment']),
          context: jStr(r['context']),
          date: DateFormat(
            'd MMM yyyy',
          ).format((jDate(r['createdAt']) ?? DateTime.now()).toLocal()),
        ),
    ],
  );
});

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  static Widget _stars(double rating, {double size = 12}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) {
      final icon = rating >= i + 1
          ? Icons.star_rounded
          : rating > i
          ? Icons.star_half_rounded
          : Icons.star_outline_rounded;
      return Icon(icon, size: size, color: AppColors.brandAmber);
    }),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_reviewsProvider);
    final summary = async.value;
    if (summary == null) {
      return LoadingView(
        error: async.hasError ? async.error.toString() : null,
        onRetry: () => ref.invalidate(_reviewsProvider),
      );
    }
    final breakdown = summary.breakdown;
    final reviews = summary.items;
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews & Ratings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      summary.count == 0
                          ? '—'
                          : summary.average.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: context.accentColor,
                      ),
                    ),
                    _stars(summary.average),
                    const SizedBox(height: 3),
                    Text(
                      '${summary.count} reviews',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.textSubColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      for (final b in breakdown)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                '${b.$1}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: context.textSubColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: b.$2,
                                    minHeight: 5,
                                    color: AppColors.brandAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('What people say'),
          if (reviews.isEmpty)
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No reviews yet. They appear here after you finish work together.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: context.textSubColor),
              ),
            ),
          for (final r in reviews) ...[
            SoftCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(name: r.name, size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: headingColor(context),
                              ),
                            ),
                            Text(
                              '${r.context} · ${r.date}',
                              style: TextStyle(
                                fontSize: 9,
                                color: context.textSubColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _stars(r.rating, size: 11),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.comment,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.45,
                      color: context.textSubColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}
