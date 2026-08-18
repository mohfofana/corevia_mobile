import 'package:corevia_mobile/features/booking/domain/entities/doctor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Doctor.fromJson', () {
    test('parses all fields', () {
      final doctor = Doctor.fromJson({
        'id': 'd1',
        'userId': 'u1',
        'specialty': 'Cardiologie',
        'address': '1 rue de la Santé',
        'city': 'Paris',
        'name': 'Dr House',
      });

      expect(doctor.id, 'd1');
      expect(doctor.userId, 'u1');
      expect(doctor.specialty, 'Cardiologie');
      expect(doctor.address, '1 rue de la Santé');
      expect(doctor.city, 'Paris');
      expect(doctor.name, 'Dr House');
    });

    test('defaults missing fields to empty strings', () {
      final doctor = Doctor.fromJson(const {});

      expect(doctor.id, '');
      expect(doctor.name, '');
      expect(doctor.city, '');
    });
  });
}
