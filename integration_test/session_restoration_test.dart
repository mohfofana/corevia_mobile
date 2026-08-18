import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'an authenticated session with a persisted last route reopens directly on it',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      // Mirrors main()'s computation: authenticated + onboarding done +
      // a persisted last route means the router should open on that route
      // directly, instead of the default /home.
      final app = buildTestApp(
        onboardingNeeded: false,
        isLoggedIn: true,
        initialLocation: '/pillbox',
        restoredLocation: '/pillbox',
      );

      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      expect(find.text('Medication Plan'), findsOneWidget);
      // Never redirected through /login or /onboarding.
      expect(find.text('Se connecter'), findsNothing);
      expect(find.text('Commencer'), findsNothing);
    },
  );
}
