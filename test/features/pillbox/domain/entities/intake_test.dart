import 'package:corevia_mobile/features/pillbox/domain/entities/intake.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({
  dynamic quantity = 1.5,
  String? takenAt,
}) {
  return {
    'id': 'i1',
    'patientMedicationId': 'pm1',
    'scheduleId': 's1',
    'medicationName': 'Doliprane',
    'medicationForm': 'comprimé',
    'dosageLabel': '500mg',
    'scheduledTime': '08:00',
    'intakeMoment': 'MORNING',
    'quantity': quantity,
    'unit': 'cp',
    'status': 'PENDING',
    'takenAt': takenAt,
    'notes': 'note',
  };
}

void main() {
  group('Intake.fromJson', () {
    test('parses a numeric quantity', () {
      final intake = Intake.fromJson(_json(quantity: 2));

      expect(intake.quantity, 2.0);
    });

    test('parses a string quantity', () {
      final intake = Intake.fromJson(_json(quantity: '1.5'));

      expect(intake.quantity, 1.5);
    });

    test('defaults intakeMoment to CUSTOM when missing', () {
      final json = _json()..remove('intakeMoment');
      final intake = Intake.fromJson(json);

      expect(intake.intakeMoment, 'CUSTOM');
    });

    test('parses takenAt when present and leaves it null otherwise', () {
      final withTakenAt = Intake.fromJson(_json(takenAt: '2026-01-01T08:00:00.000Z'));
      final withoutTakenAt = Intake.fromJson(_json());

      expect(withTakenAt.takenAt, isNotNull);
      expect(withoutTakenAt.takenAt, isNull);
    });
  });

  group('Intake.toJson', () {
    test('round-trips scalar fields', () {
      final intake = Intake.fromJson(_json());

      final json = intake.toJson();

      expect(json['medicationName'], 'Doliprane');
      expect(json['quantity'], 1.5);
      expect(json['status'], 'PENDING');
    });
  });

  group('Intake.copyWith', () {
    test('overrides status, takenAt and notes only', () {
      final intake = Intake.fromJson(_json());
      final now = DateTime(2026, 1, 1);

      final updated = intake.copyWith(status: 'TAKEN', takenAt: now, notes: 'ok');

      expect(updated.status, 'TAKEN');
      expect(updated.takenAt, now);
      expect(updated.notes, 'ok');
      expect(updated.id, intake.id);
      expect(updated.medicationName, intake.medicationName);
    });

    test('keeps existing values when nothing is overridden', () {
      final intake = Intake.fromJson(_json());

      final updated = intake.copyWith();

      expect(updated.status, intake.status);
      expect(updated.notes, intake.notes);
    });
  });
}
