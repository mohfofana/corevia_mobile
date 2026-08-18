import 'package:corevia_mobile/features/pillbox/domain/entities/patient_medication.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json() => {
      'id': 'pm1',
      'patientId': 'p1',
      'medicationName': 'Doliprane',
      'medicationForm': 'comprimé',
      'dosageLabel': '500mg',
      'instructions': 'Après repas',
      'startDate': '2026-01-01T00:00:00.000Z',
      'endDate': '2026-02-01T00:00:00.000Z',
      'isActive': true,
      'cis': '123',
      'cip': '456',
      'medicationExternalId': 'ext1',
      'source': 'BDPM',
      'activeSubstances': ['paracetamol'],
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-02T00:00:00.000Z',
      'schedules': [
        {
          'id': 's1',
          'patientMedicationId': 'pm1',
          'intakeTime': '08:00',
          'intakeMoment': 'MORNING',
          'weekday': 1,
          'quantity': 1,
        },
      ],
    };

void main() {
  group('PatientMedication.fromJson', () {
    test('parses all nested fields', () {
      final medication = PatientMedication.fromJson(_json());

      expect(medication.id, 'pm1');
      expect(medication.isActive, isTrue);
      expect(medication.activeSubstances, ['paracetamol']);
      expect(medication.schedules, hasLength(1));
      expect(medication.schedules.first.intakeMoment, 'MORNING');
    });

    test('defaults isActive to false and lists to empty when absent', () {
      final medication = PatientMedication.fromJson({
        'id': 'pm1',
        'patientId': 'p1',
        'medicationName': 'Doliprane',
        'startDate': '2026-01-01T00:00:00.000Z',
      });

      expect(medication.isActive, isFalse);
      expect(medication.activeSubstances, isEmpty);
      expect(medication.schedules, isEmpty);
      expect(medication.endDate, isNull);
    });
  });

  group('PatientMedication.toJson', () {
    test('serializes dates as ISO 8601 strings and nested schedules', () {
      final medication = PatientMedication.fromJson(_json());

      final json = medication.toJson();

      expect(json['startDate'], medication.startDate.toIso8601String());
      expect(json['schedules'], hasLength(1));
    });
  });

  group('PatientMedication.copyWith', () {
    test('overrides only the given fields, keeping identity fields', () {
      final medication = PatientMedication.fromJson(_json());

      final updated = medication.copyWith(dosageLabel: '1000mg', isActive: false);

      expect(updated.dosageLabel, '1000mg');
      expect(updated.isActive, isFalse);
      expect(updated.id, medication.id);
      expect(updated.medicationName, medication.medicationName);
    });
  });
}
