import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import 'core/notification/pillbox_notification.dart';
import 'core/routes/app_router.dart';
import 'core/routes/route_persistence.dart';
import 'shared/theme/app_theme.dart';
import 'features/home/presentation/providers/home_provider.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/account/presentation/providers/user_provider.dart';
import 'features/account/data/repositories/user_repository_impl.dart';
import 'features/pillbox/data/repositories/pillbox_repository_impl.dart';
import 'features/pillbox/presentation/providers/medication_search_provider.dart';
import 'features/documents/presentation/providers/document_provider.dart';
import 'features/pillbox/presentation/providers/pillbox_provider.dart';
import 'features/booking/data/repositories/booking_repository_impl.dart';
import 'features/booking/presentation/providers/booking_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/notifiers.dart';
import 'networking/api_service.dart';
import 'networking/routes/user_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    await initializeDateFormatting('fr_FR', null);
    await initializeDateFormatting('en_US', null);
  } catch (e) {
    // Keep boot resilient in dev setups where `.env` isn't present yet.
    debugPrint('⚠️  Unable to load .env (continuing): $e');
  }

  // Initialize timezones and set device local timezone
  tz_data.initializeTimeZones();
  try {
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));
  } catch (_) {
    // Fallback to UTC if timezone is not recognized
  }

  // Onboarding
  final prefs = await SharedPreferences.getInstance();
  bool? hasCompletedOnboarding = prefs.getBool('onboarding_done');
  bool onboardingNeeded =
      (hasCompletedOnboarding == null || hasCompletedOnboarding == false);

  debugPrint('hasCompletedOnboarding: $hasCompletedOnboarding');
  debugPrint('onboardingNeeded: $onboardingNeeded');

  final onboardingNotifier = OnboardingNotifier(onboardingNeeded);
  final authNotifier = AuthNotifier(false);
  final localeNotifier = LocaleNotifier(await LocaleNotifier.load());

  // Restore local session first (persistent login)
  const secureStorage = FlutterSecureStorage();
  final token = await secureStorage.read(key: 'auth_token');
  if (token != null && token.isNotEmpty) {
    authNotifier.value = true;

    // Validate token using an endpoint that supports Bearer auth.
    // Keep the user logged in unless backend explicitly says unauthorized.
    try {
      final me = await ApiService.authGet(UserRoutes.me());
      final hasUser = me is Map<String, dynamic> && me['user'] != null;
      if (!hasUser) {
        await secureStorage.delete(key: 'auth_token');
        authNotifier.value = false;
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('403')) {
        await secureStorage.delete(key: 'auth_token');
        authNotifier.value = false;
      }
    }
  }

  final restoredLocation =
      sanitizeRestorableRoute(prefs.getString(lastRouteStorageKey));
  final initialLocation =
      (authNotifier.value && !onboardingNeeded) ? restoredLocation : '/';

  // Create provider & router before notification init so handlers can use them
  final pillboxProvider = PillboxProvider(PillboxRepositoryImpl());
  final router = createRouter(
    onboardingNotifier,
    authNotifier,
    initialLocation: initialLocation,
    restoredLocation: restoredLocation,
  );

  router.routerDelegate.addListener(() {
    if (!authNotifier.value) return;
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    if (isRestorableRoute(location)) {
      prefs.setString(lastRouteStorageKey, location);
    }
  });

  authNotifier.addListener(() {
    if (!authNotifier.value) {
      prefs.remove(lastRouteStorageKey);
    }
  });

  // Wire interactive notification actions
  setPillboxNotificationHandlers(
    onAction: (intakeId, action) async {
      if (action == 'taken') {
        await pillboxProvider.markIntakeTaken(intakeId);
      } else if (action == 'skipped') {
        await pillboxProvider.markIntakeSkipped(intakeId);
      }
      await pillboxProvider.loadTodayIntakes();
    },
    onTap: () {
      router.go('/home');
    },
  );
  await initializePillboxNotifications();

  // Load user data from cache
  final userProvider = UserProvider(UserRepositoryImpl());
  await userProvider.loadUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeProvider(HomeRepositoryImpl()),
        ),
        ChangeNotifierProvider<PillboxProvider>.value(
          value: pillboxProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => MedicationSearchProvider(PillboxRepositoryImpl()),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(BookingRepositoryImpl()),
        ),
        ChangeNotifierProvider<UserProvider>.value(
          value: userProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => DocumentProvider(),
        ),
        ChangeNotifierProvider<OnboardingNotifier>.value(
          value: onboardingNotifier,
        ),
        ChangeNotifierProvider<AuthNotifier>.value(
          value: authNotifier,
        ),
        ChangeNotifierProvider<LocaleNotifier>.value(
          value: localeNotifier,
        ),
      ],
      child: MyApp(router: router),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;

  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final localeNotifier = context.watch<LocaleNotifier>();
    final locale = localeNotifier.value;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.appName,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: locale,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
