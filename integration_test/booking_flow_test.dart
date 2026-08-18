import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corevia_mobile/networking/api_service.dart';

import 'support/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test.local');
  });

  setUp(() {
    // HomeScreen fetches the current user directly via ApiService; the
    // failure is caught silently, but stub it so the journey stays offline.
    ApiService.debugOverrideClient(MockClient((_) async => http.Response('', 401)));
  });

  tearDown(() {
    ApiService.debugResetClient();
  });

  testWidgets(
    'picking a slot and confirming creates an appointment and shows the confirmation screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      final app = buildTestApp(
        onboardingNeeded: false,
        isLoggedIn: true,
        initialLocation: '/home',
        restoredLocation: '/home',
      );

      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      app.router.push(
        '/calendar/booking',
        extra: {
          'doctorId': 'd1',
          'doctorName': 'Dr House',
          'specialty': 'Cardiologie',
          'imageUrl': '',
          'address': '1 rue de la Santé',
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr House'), findsWidgets);
      expect(find.text('09:00'), findsOneWidget);

      await tester.tap(find.text('09:00'));
      await tester.pump();

      await tester.tap(find.text('Confirmer le rendez-vous'));
      await tester.pump();
      // The confirmation screen runs a repeating pulse AnimationController.
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Demande envoyée !'), findsOneWidget);
      expect(find.text('Dr House'), findsWidgets);
      expect(find.text('09:00'), findsOneWidget);
    },
  );
}
