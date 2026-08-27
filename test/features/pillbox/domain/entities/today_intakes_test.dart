import 'package:corevia_mobile/features/pillbox/domain/entities/today_intakes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodayIntakes.fromJson', () {
    test('parses the date and nested intakes', () {
      final result = TodayIntakes.fromJson({
        'date': '2026-01-01',
        'intakes': [
          {
            'id': 'i1',
            'patientMedicationId': 'pm1',
            'scheduleId': 's1',
            'medicationName': 'Doliprane',
            'scheduledTime': '08:00',
            'intakeMoment': 'MORNING',
            'status': 'PENDING',
          },
        ],
      });

      expect(result.date, DateTime.parse('2026-01-01'));
      expect(result.intakes, hasLength(1));
      expect(result.intakes.first.medicationName, 'Doliprane');
    });

    test('defaults intakes to an empty list when absent', () {
      final result = TodayIntakes.fromJson({'date': '2026-01-01'});

      expect(result.intakes, isEmpty);
    });

    test('falls back to fallbackDate when the date is missing or invalid', () {
      final fallback = DateTime(2026, 2, 2);

      final result = TodayIntakes.fromJson({}, fallbackDate: fallback);

      expect(result.date, fallback);
    });

    test('throws when both date and fallbackDate are unavailable', () {
      expect(() => TodayIntakes.fromJson(const {}), throwsFormatException);
    });
  });
}
