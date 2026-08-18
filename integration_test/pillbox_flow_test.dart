import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corevia_mobile/networking/api_service.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test.local');
  });

  setUp(() {
    ApiService.debugOverrideClient(MockClient((_) async => http.Response('', 401)));
  });

  tearDown(() {
    ApiService.debugResetClient();
  });

  testWidgets(
    "marking today's intake as taken updates the intake card status",
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final pillboxRepository = FakePillboxRepository();

      final app = buildTestApp(
        onboardingNeeded: false,
        isLoggedIn: true,
        initialLocation: '/home',
        restoredLocation: '/home',
        pillboxRepository: pillboxRepository,
      );

      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      expect(find.text('Doliprane'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pumpAndSettle();

      // The intake card now shows a "Pris" badge instead of the action
      // buttons (the weekly-calendar day badge also turns into a check
      // icon once the day is fully taken, so we assert on the card text
      // rather than global icon absence).
      expect(find.text('Pris'), findsOneWidget);
    },
  );
}
