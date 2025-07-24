import 'package:flutter_test/flutter_test.dart';
import 'package:memora/main.dart';
import 'package:memora/screens/home_screen.dart';
import 'package:memora/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  // Set up a mock for SharedPreferences before running tests
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test: Navigates to OnboardingScreen for new users',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(createTestableWidget(child: const MyApp()));

    // Wait for the splash screen animations and navigation to complete.
    // Using pumpAndSettle will wait for all animations to finish.
    await tester.pumpAndSettle();

    // Verify that for a new user (no level set), we land on the OnboardingScreen.
    expect(find.byType(OnboardingScreen), findsOneWidget);
    // Also, verify that the HomeScreen is not present.
    expect(find.byType(HomeScreen), findsNothing);
  });
}
