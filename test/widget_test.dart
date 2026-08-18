import 'package:flutter_test/flutter_test.dart';
import 'package:corevia_mobile/main.dart';
import 'package:corevia_mobile/core/providers/notifiers.dart';
import 'package:corevia_mobile/core/routes/app_router.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final onboardingNotifier = OnboardingNotifier(true);
    final authNotifier = AuthNotifier(false);
    final router = createRouter(onboardingNotifier, authNotifier);

    await tester.pumpWidget(MyApp(router: router));
    // The onboarding screen runs a repeating AnimationController, so
    // pumpAndSettle() never settles here — pump a few frames instead.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}
