import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:subkamyaab_recruiter_app/app.dart';
import 'package:subkamyaab_recruiter_app/core/constants/app_strings.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: RecruiterApp()));
    await tester.pump();

    expect(find.bySemanticsLabel(AppStrings.appName), findsOneWidget);

    // Flush the splash screen's delayed navigation timer before teardown.
    await tester.pump(const Duration(milliseconds: 2500));
  });
}
