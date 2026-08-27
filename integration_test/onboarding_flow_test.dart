import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a fresh install shows onboarding, and finishing it redirects to login',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      final app = buildTestApp(onboardingNeeded: true, isLoggedIn: false);
      await tester.pumpWidget(app.widget);
      // The onboarding screen runs a repeating AnimationController, so
      // pumpAndSettle() never settles here — pump bounded frames instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Commencer'), findsOneWidget);

      await tester.tap(find.text('Commencer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The login screen also runs repeating animations.
      expect(find.text('Se connecter'), findsOneWidget);
    },
  );
}
