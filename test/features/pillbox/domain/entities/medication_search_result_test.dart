import 'package:corevia_mobile/features/pillbox/domain/entities/medication_search_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicationSearchResult.fromJson', () {
    test('parses a numeric price', () {
      final result = MedicationSearchResult.fromJson({
        'externalId': 'e1',
        'name': 'Doliprane',
        'price': 2.5,
      });

      expect(result.price, 2.5);
    });

    test('parses a string price', () {
      final result = MedicationSearchResult.fromJson({
        'externalId': 'e1',
        'name': 'Doliprane',
        'price': '3.10',
      });

      expect(result.price, 3.10);
    });

    test('parses active substances and defaults to an empty list when absent', () {
      final withSubstances = MedicationSearchResult.fromJson({
        'externalId': 'e1',
        'name': 'Doliprane',
        'activeSubstances': ['paracetamol'],
      });
      final withoutSubstances = MedicationSearchResult.fromJson({
        'externalId': 'e1',
        'name': 'Doliprane',
      });

      expect(withSubstances.activeSubstances, ['paracetamol']);
      expect(withoutSubstances.activeSubstances, isEmpty);
    });

    test('defaults required fields to empty strings when missing', () {
      final result = MedicationSearchResult.fromJson(const {});

      expect(result.externalId, '');
      expect(result.name, '');
      expect(result.price, isNull);
    });
  });
}
