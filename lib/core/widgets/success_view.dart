import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/extensions.dart';
import 'ui_kit.dart';

/// Full-screen "done" state shown after posting, hiring, sending an offer…
class SuccessView extends StatelessWidget {
  const SuccessView({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.icon = Icons.check_circle_rounded,
    this.color = AppColors.tintGreen,
    this.details,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData icon;
  final Color color;

  /// Optional summary card under the message.
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(icon, size: 56, color: color),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: headingColor(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.45,
                  color: context.textSubColor,
                ),
              ),
              if (details != null) ...[const SizedBox(height: 16), details!],
              const Spacer(),
              ElevatedButton(onPressed: onPrimary, child: Text(primaryLabel)),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
