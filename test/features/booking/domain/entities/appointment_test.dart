import 'package:corevia_mobile/features/booking/domain/entities/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentDoctorInfo.fromJson', () {
    test('parses all fields', () {
      final doctor = AppointmentDoctorInfo.fromJson({
        'id': 'd1',
        'name': 'Dr House',
        'specialty': 'Diagnostics',
        'address': '1 rue de la Santé',
      });

      expect(doctor.id, 'd1');
      expect(doctor.name, 'Dr House');
      expect(doctor.specialty, 'Diagnostics');
      expect(doctor.address, '1 rue de la Santé');
    });
  });

  group('Appointment.fromJson', () {
    test('parses a nested doctor object', () {
      final appointment = Appointment.fromJson({
        'id': 'a1',
        'doctorId': 'd1',
        'patientId': 'p1',
        'date': '2026-01-01',
        'time': '10:00',
        'status': 'confirmed',
        'reason': 'Checkup',
        'doctor': {
          'id': 'd1',
          'name': 'Dr House',
          'specialty': 'Diagnostics',
          'address': 'Somewhere',
        },
      });

      expect(appointment.id, 'a1');
      expect(appointment.status, 'confirmed');
      expect(appointment.reason, 'Checkup');
      expect(appointment.doctor, isNotNull);
      expect(appointment.doctor!.name, 'Dr House');
    });

    test('leaves doctor null when absent, and optional fields null', () {
      final appointment = Appointment.fromJson({
        'id': 'a1',
        'doctorId': 'd1',
        'patientId': 'p1',
        'date': '2026-01-01',
        'time': '10:00',
        'status': 'pending',
      });

      expect(appointment.doctor, isNull);
      expect(appointment.reason, isNull);
      expect(appointment.createdAt, isNull);
      expect(appointment.updatedAt, isNull);
    });

    test('defaults missing required fields to empty strings', () {
      final appointment = Appointment.fromJson(const {});

      expect(appointment.id, '');
      expect(appointment.doctorId, '');
      expect(appointment.status, '');
    });
  });
}
