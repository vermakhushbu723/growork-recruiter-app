import 'package:flutter/material.dart';
import '../utils/extensions.dart';

/// Used both as an empty-state and as the "coming soon" placeholder
/// for modules whose deep functionality lands in a later phase.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.tagBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: context.accentColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen spinner while data loads; [error] shows a retry state.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.error, this.onRetry, this.appBar = true});

  final String? error;
  final VoidCallback? onRetry;
  final bool appBar;

  @override
  Widget build(BuildContext context) {
    final body = error == null
        ? const Center(child: CircularProgressIndicator())
        : EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Couldn’t load this',
            message: error,
            actionLabel: onRetry == null ? null : 'Try again',
            onAction: onRetry,
          );
    return appBar ? Scaffold(appBar: AppBar(), body: body) : body;
  }
}
