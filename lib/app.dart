import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class RecruiterApp extends ConsumerWidget {
  const RecruiterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Clamp the system font-size setting so a user's "Large text"
        // accessibility preference can't blow past what our fixed-height
        // cards/bars were designed for and cause overflow on small phones.
        final mq = MediaQuery.of(context);
        final clampedScaler = mq.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.25,
        );
        // Android 15+ draws the app edge-to-edge, so the system navigation
        // bar sits on top of our content. Reserve its height once here so no
        // screen (chat input, sheets, bottom buttons) is ever hidden behind it.
        final navInset = mq.padding.bottom;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: EdgeInsets.only(bottom: navInset),
            child: MediaQuery(
              data: mq.copyWith(
                textScaler: clampedScaler,
                padding: mq.padding.copyWith(bottom: 0),
                viewPadding: mq.viewPadding.copyWith(bottom: 0),
                viewInsets: mq.viewInsets.copyWith(
                  bottom: (mq.viewInsets.bottom - navInset).clamp(
                    0,
                    double.infinity,
                  ),
                ),
              ),
              child: child!,
            ),
          ),
        );
      },
    );
  }
}
