import 'package:corevia_mobile/features/booking/domain/entities/available_slots.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvailableSlots.fromJson', () {
    test('parses slots as strings', () {
      final slots = AvailableSlots.fromJson({
        'doctorId': 'd1',
        'date': '2026-01-01',
        'slots': ['09:00', '09:30'],
      });

      expect(slots.doctorId, 'd1');
      expect(slots.date, '2026-01-01');
      expect(slots.slots, ['09:00', '09:30']);
    });

    test('defaults slots to an empty list when absent', () {
      final slots = AvailableSlots.fromJson({
        'doctorId': 'd1',
        'date': '2026-01-01',
      });

      expect(slots.slots, isEmpty);
    });
  });
}
