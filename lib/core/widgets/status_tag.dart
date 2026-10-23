import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum TagVariant { job, remote, urgent }

/// Small pill tag matching the website's .tag utility (job-tag, remote-tag, etc.)
class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    this.variant = TagVariant.job,
  });

  final String label;
  final TagVariant variant;

  ({Color bg, Color fg}) get _colors => switch (variant) {
    TagVariant.job => (bg: AppColors.jobTagBg, fg: AppColors.jobTagTxt),
    TagVariant.remote => (bg: AppColors.remoteBg, fg: AppColors.remoteTxt),
    TagVariant.urgent => (bg: AppColors.urgentBg, fg: AppColors.urgentTxt),
  };

  @override
  Widget build(BuildContext context) {
    var colors = _colors;
    if (Theme.of(context).brightness == Brightness.dark) {
      // Light pastel pills glare on dark surfaces; use a tinted chip instead.
      final fg = variant == TagVariant.job ? AppColors.primaryLight : colors.fg;
      colors = (bg: fg.withValues(alpha: 0.18), fg: fg);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
