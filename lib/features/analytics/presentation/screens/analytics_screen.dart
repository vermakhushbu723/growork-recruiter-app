import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../freelance/data/project_models.dart';
import '../../../jobs/data/job_post_model.dart';
import '../../../jobs/providers/recruitment_provider.dart';
import '../../../wallet/providers/wallet_provider.dart';

const _periods = {'7 days': 7, '30 days': 30, '90 days': 90};

/// Applications received per day / week / month for the chosen period.
final _seriesProvider = FutureProvider.autoDispose
    .family<List<(String, int)>, int>((ref, days) async {
      final d = jMap(await api.get('/recruiter/analytics', query: {'period': days}));
      return [
        for (final b in jMapList(d['series']))
          (jStr(b['label']), jInt(b['count'])),
      ];
    });

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _period = '7 days';

  @override
  Widget build(BuildContext context) {
    final hiring = ref.watch(recruitmentProvider);
    final wallet = ref.watch(walletProvider);
    final views = hiring.jobs.fold(0, (s, j) => s + j.views);
    final apps = hiring.applicants.length;
    int reached(ApplicantStatus s) => hiring.applicants
        .where(
          (a) =>
              a.status.index >= s.index && a.status != ApplicantStatus.rejected,
        )
        .length;
    final funnel = [
      ('Applied', apps),
      ('Shortlisted', reached(ApplicantStatus.shortlisted)),
      ('Interview', reached(ApplicantStatus.interview)),
      ('Offered', reached(ApplicantStatus.offered)),
      ('Hired', reached(ApplicantStatus.hired)),
    ];
    final topJobs = [...hiring.jobs.where((j) => j.views > 0)]
      ..sort((a, b) => b.views.compareTo(a.views));

    return Scaffold(
      appBar: AppBar(title: const Text('Hiring Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
        children: [
          Row(
            children: [
              for (final p in _periods.keys)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: PillChip(
                    label: 'Last $p',
                    height: 22,
                    selected: _period == p,
                    onTap: () => setState(() => _period = p),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 3.1,
            children: [
              StatBox(
                label: 'Job post views',
                value: '$views',
                icon: Icons.visibility_outlined,
                color: AppColors.tintPurple,
              ),
              StatBox(
                label: 'Applications',
                value: '$apps',
                icon: Icons.people_alt_outlined,
                color: AppColors.tintBlue,
              ),
              StatBox(
                label: 'View → apply rate',
                value: views == 0
                    ? '—'
                    : '${(apps / views * 100).toStringAsFixed(1)}%',
                icon: Icons.trending_up_rounded,
                color: AppColors.tintGreen,
              ),
              StatBox(
                label: 'Upcoming interviews',
                value: '${hiring.upcomingInterviews.length}',
                icon: Icons.event_outlined,
                color: AppColors.tintOrange,
              ),
              StatBox(
                label: 'Hires',
                value: '${hiring.totalHired}',
                icon: Icons.verified_outlined,
                color: AppColors.tintTeal,
              ),
              StatBox(
                label: 'Freelance spend',
                value: formatRupees(wallet.spentThisMonth),
                icon: Icons.payments_outlined,
                color: AppColors.tintRed,
              ),
            ],
          ),
          const SectionLabel('Applications received'),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: ref
                .watch(_seriesProvider(_periods[_period]!))
                .when(
                  data: (data) => _BarChart(data: data),
                  loading: () => const SizedBox(
                    height: 170,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        e.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textSubColor,
                        ),
                      ),
                    ),
                  ),
                ),
          ),
          const SectionLabel('Hiring funnel'),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                for (final (i, f) in funnel.indexed)
                  _FunnelRow(
                    label: f.$1,
                    value: f.$2,
                    max: funnel.first.$2,
                    conversion: i == 0 || funnel[i - 1].$2 == 0
                        ? null
                        : f.$2 / funnel[i - 1].$2,
                  ),
              ],
            ),
          ),
          const SectionLabel('Top job posts by views'),
          for (final j in topJobs.take(4)) ...[
            MenuTile(
              icon: Icons.work_outline_rounded,
              title: j.title,
              subtitle:
                  '${j.views} views · ${hiring.applicantsFor(j.id).length} applicants · ${j.status.label}',
              onTap: () => context.push(RoutePaths.jobDetails, extra: j.id),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

/// Single-series column chart; tap a bar to read its value.
class _BarChart extends StatefulWidget {
  const _BarChart({required this.data});

  final List<(String, int)> data;

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  int? _selected;

  @override
  void didUpdateWidget(covariant _BarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final max = data.fold(0, (m, d) => d.$2 > m ? d.$2 : m);
    final total = data.fold(0, (s, d) => s + d.$2);
    final sel = _selected;
    const plotHeight = 120.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sel == null ? '$total' : '${data[sel].$2}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: headingColor(context),
          ),
        ),
        Text(
          sel == null ? 'Total in this period · tap a bar' : data[sel].$1,
          style: TextStyle(fontSize: 9, color: context.textSubColor),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: plotHeight + 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, d) in data.indexed)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _selected = sel == i ? null : i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: 18,
                          height: max == 0 ? 0 : plotHeight * d.$2 / max,
                          decoration: BoxDecoration(
                            color: sel == null || sel == i
                                ? kButtonBlue
                                : kButtonBlue.withValues(alpha: 0.3),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        Container(height: 1, color: context.borderColor),
                        const SizedBox(height: 4),
                        Text(
                          d.$1,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: sel == i
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: context.textSubColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FunnelRow extends StatelessWidget {
  const _FunnelRow({
    required this.label,
    required this.value,
    required this.max,
    this.conversion,
  });

  final String label;
  final int value;
  final int max;

  /// Share of the previous stage that reached this one.
  final double? conversion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(fontSize: 9.5, color: context.textSubColor),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 14,
                  width: max == 0 ? 0 : c.maxWidth * value / max,
                  decoration: BoxDecoration(
                    color: kButtonBlue,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text(
              conversion == null
                  ? '$value'
                  : '$value · ${(conversion! * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: headingColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
