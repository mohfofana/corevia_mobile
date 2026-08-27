import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';

// Les écrans
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/booking/presentation/screens/booking_confirmation_screen.dart';
import '../../features/booking/presentation/screens/appointments_screen.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/account/presentation/screens/edit_account_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/chat/presentation/screens/chat_screen_ai.dart'
    as ai_chat;
import '../../features/onboarding/presentation/screen/onboarding_screen.dart';
import '../../features/pillbox/presentation/screens/add_medication_screen.dart';
import '../../features/pillbox/presentation/screens/intake_history_screen.dart';
import '../../features/pillbox/presentation/screens/medication_detail_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/pillbox/presentation/screens/pillbox_screen.dart';
import 'route_persistence.dart';

// La barre de navigation
import '../../widgets/navigation_bar.dart';

GoRouter createRouter(
  ValueNotifier<bool> onboardingNotifier,
  ValueNotifier<bool> authNotifier, {
  String initialLocation = '/',
  String? restoredLocation,
}) {
  final fallbackAuthenticatedLocation =
      sanitizeRestorableRoute(restoredLocation);

  return GoRouter(
    initialLocation: initialLocation,
    // 👇 Ici : si onboarding pas encore vu → on commence par /onboarding

    refreshListenable: Listenable.merge([onboardingNotifier, authNotifier]),

    redirect: (context, state) {
      final onboardingNeeded = onboardingNotifier.value;
      final isLoggedIn = authNotifier.value;

      final location = state.uri.path;

      // Logged-in users skip login; only skip onboarding if it's completed
      if (isLoggedIn &&
          !onboardingNeeded &&
          (location == '/login' ||
              location == '/onboarding' ||
              location == '/')) {
        return fallbackAuthenticatedLocation;
      }

      if (onboardingNeeded && location != '/onboarding') {
        return '/onboarding';
      }

      if (!onboardingNeeded && location == '/onboarding') {
        return '/login';
      }

      if (!isLoggedIn && location != '/login' && location != '/onboarding') {
        return '/login';
      }

      return null;
    },

    routes: [
      // 👇 Nouvelle route pour ton onboarding
      GoRoute(
        path: '/',
        redirect: (context, state) => '/onboarding',
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Route pour la page de connexion
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Route pour une conversation spécifique
      GoRoute(
        path: '/chat/ai/:conversationId',
        builder: (context, state) => ai_chat.ChatScreen(
          conversationId: state.pathParameters['conversationId'] ?? 'new',
        ),
      ),

      // ShellRoute avec BottomNavigationBar
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                child,
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BottomNavBar(currentLocation: state.uri.path),
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: '/chat/ai/new',
            builder: (context, state) =>
                const ai_chat.ChatScreen(conversationId: 'new'),
          ),
          GoRoute(
            path: '/chat/ai/:conversationId',
            builder: (context, state) => ai_chat.ChatScreen(
              conversationId: state.pathParameters['conversationId']!,
            ),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => CalendarScreen(
              initialTab: () {
                final tab = (state.uri.queryParameters['tab'] ?? 'schedule').toLowerCase();
                return (tab == 'list' || tab == 'lists')
                    ? CalendarTab.list
                    : CalendarTab.programme;
              }(),
            ),
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountScreen(),
          ),
        ],
      ),

      // Routes sans NavBar
      GoRoute(
        path: '/edit-account',
        builder: (context, state) => const EditAccountScreen(),
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const AppointmentsScreen(),
      ),
      GoRoute(
        path: '/calendar/booking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BookingScreen(
            doctorId: extra['doctorId'] as String? ?? '',
            doctorName: extra['doctorName'] as String? ?? context.l10n.doctor,
            specialty: extra['specialty'] as String? ?? '',
            imageUrl: extra['imageUrl'] as String? ?? '',
            address: extra['address'] as String? ?? context.l10n.notProvided,
          );
        },
      ),
      GoRoute(
        path: '/calendar/booking/confirmation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BookingConfirmationScreen(
            doctorId: extra['doctorId'] as String? ?? '',
            doctorName: extra['doctorName'] as String? ?? context.l10n.doctor,
            specialty: extra['specialty'] as String? ?? '',
            imageUrl: extra['imageUrl'] as String? ?? '',
            address: extra['address'] as String? ?? context.l10n.notProvided,
            date: extra['date'] as DateTime? ?? DateTime.now(),
            timeSlot: extra['timeSlot'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: '/pillbox',
        builder: (context, state) => const PillboxScreen(),
      ),
      GoRoute(
        path: '/pillbox/history',
        builder: (context, state) => const IntakeHistoryScreen(),
      ),
      GoRoute(
        path: '/pillbox/add',
        builder: (context, state) => const AddMedicationScreen(),
      ),
      GoRoute(
        path: '/pillbox/:id',
        builder: (context, state) => MedicationDetailScreen(
          medicationId: state.pathParameters['id'] ?? '',
        ),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(context.l10n.pageNotFound(state.uri.toString())),
      ),
    ),
  );
}
