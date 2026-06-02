// Smoke test: the app boots to the phone-number screen for a logged-out user.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:upi/app/echopay_app.dart';
import 'package:upi/core/providers/core_providers.dart';

void main() {
  testWidgets('App boots to sign-in when logged out', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const EchoPayApp(),
      ),
    );
    await tester.pump();

    expect(find.text('sign in'), findsOneWidget);
  });
}
