import 'package:corevia_mobile/core/routes/route_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isRestorableRoute', () {
    test('rejects an empty location', () {
      expect(isRestorableRoute(''), isFalse);
    });

    test('rejects the root, login and onboarding routes', () {
      expect(isRestorableRoute('/'), isFalse);
      expect(isRestorableRoute('/login'), isFalse);
      expect(isRestorableRoute('/onboarding'), isFalse);
    });

    test('rejects the booking screens that rely on runtime extras', () {
      expect(isRestorableRoute('/calendar/booking'), isFalse);
      expect(isRestorableRoute('/calendar/booking/confirmation'), isFalse);
    });

    test('accepts a normal app route', () {
      expect(isRestorableRoute('/pillbox'), isTrue);
      expect(isRestorableRoute('/home'), isTrue);
    });

    test('rejects an unparsable location', () {
      expect(isRestorableRoute('not a uri::'), isFalse);
    });
  });

  group('sanitizeRestorableRoute', () {
    test('falls back to the default route when null or blank', () {
      expect(sanitizeRestorableRoute(null), defaultAuthenticatedRoute);
      expect(sanitizeRestorableRoute('   '), defaultAuthenticatedRoute);
    });

    test('passes through a valid restorable route', () {
      expect(sanitizeRestorableRoute('/pillbox'), '/pillbox');
    });

    test('falls back to the default route for a non-restorable location', () {
      expect(sanitizeRestorableRoute('/login'), defaultAuthenticatedRoute);
    });
  });
}
