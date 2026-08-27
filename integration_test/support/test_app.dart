import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:corevia_mobile/core/providers/notifiers.dart';
import 'package:corevia_mobile/core/routes/app_router.dart';
import 'package:corevia_mobile/features/account/domain/repositories/user_repository.dart';
import 'package:corevia_mobile/features/account/presentation/providers/user_provider.dart';
import 'package:corevia_mobile/features/booking/domain/repositories/booking_repository.dart';
import 'package:corevia_mobile/features/booking/presentation/providers/booking_provider.dart';
import 'package:corevia_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:corevia_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:corevia_mobile/features/pillbox/domain/repositories/pillbox_repository.dart';
import 'package:corevia_mobile/features/pillbox/presentation/providers/medication_search_provider.dart';
import 'package:corevia_mobile/features/pillbox/presentation/providers/pillbox_provider.dart';
import 'package:corevia_mobile/main.dart';

import 'fakes.dart';

/// Builds the same widget tree as `main()` (MultiProvider + MyApp/GoRouter),
/// but wired to fake repositories instead of the real network — this is what
/// lets the functional journeys drive real screens/providers/router logic
/// end to end without a backend.
class TestApp {
  final GoRouter router;
  final OnboardingNotifier onboardingNotifier;
  final AuthNotifier authNotifier;
  final Widget widget;

  TestApp({
    required this.router,
    required this.onboardingNotifier,
    required this.authNotifier,
    required this.widget,
  });
}

TestApp buildTestApp({
  required bool onboardingNeeded,
  required bool isLoggedIn,
  String initialLocation = '/',
  String? restoredLocation,
  BookingRepository? bookingRepository,
  PillboxRepository? pillboxRepository,
  UserRepository? userRepository,
  HomeRepository? homeRepository,
}) {
  final onboardingNotifier = OnboardingNotifier(onboardingNeeded);
  final authNotifier = AuthNotifier(isLoggedIn);
  final router = createRouter(
    onboardingNotifier,
    authNotifier,
    initialLocation: initialLocation,
    restoredLocation: restoredLocation,
  );
  final pillbox = pillboxRepository ?? FakePillboxRepository();

  final widget = MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => HomeProvider(homeRepository ?? FakeHomeRepository())),
      ChangeNotifierProvider(create: (_) => PillboxProvider(pillbox)),
      ChangeNotifierProvider(create: (_) => MedicationSearchProvider(pillbox)),
      ChangeNotifierProvider(create: (_) => BookingProvider(bookingRepository ?? FakeBookingRepository())),
      ChangeNotifierProvider(create: (_) => UserProvider(userRepository ?? FakeUserRepository())),
      ChangeNotifierProvider<OnboardingNotifier>.value(value: onboardingNotifier),
      ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
      ChangeNotifierProvider<LocaleNotifier>.value(
        value: LocaleNotifier(const Locale('fr')),
      ),
    ],
    child: MyApp(router: router),
  );

  return TestApp(
    router: router,
    onboardingNotifier: onboardingNotifier,
    authNotifier: authNotifier,
    widget: widget,
  );
}
