import 'package:corevia_mobile/features/pillbox/domain/entities/medication_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicationSchedule.fromJson', () {
    test('parses weekday and quantity from strings', () {
      final schedule = MedicationSchedule.fromJson({
        'id': '1',
        'patientMedicationId': 'pm-1',
        'intakeTime': '08:00',
        'intakeMoment': 'MORNING',
        'weekday': '2',
        'quantity': '1.5',
        'unit': 'cp',
      });

      expect(schedule.weekday, 2);
      expect(schedule.quantity, 1.5);
      expect(schedule.unit, 'cp');
    });

    test('parses numeric values directly', () {
      final schedule = MedicationSchedule.fromJson({
        'id': '2',
        'patientMedicationId': 'pm-2',
        'intakeTime': '12:00',
        'intakeMoment': 'NOON',
        'weekday': 5,
        'quantity': 2,
      });

      expect(schedule.weekday, 5);
      expect(schedule.quantity, 2.0);
    });
  });
}
