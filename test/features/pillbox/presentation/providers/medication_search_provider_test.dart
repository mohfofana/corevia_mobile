import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/medication_search_result.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/paginated_response.dart';
import 'package:corevia_mobile/features/pillbox/domain/repositories/pillbox_repository.dart';
import 'package:corevia_mobile/features/pillbox/presentation/providers/medication_search_provider.dart';

class MockPillboxRepository extends Mock implements PillboxRepository {}

void main() {
  late MockPillboxRepository repository;
  late MedicationSearchProvider provider;

  setUp(() {
    repository = MockPillboxRepository();
    provider = MedicationSearchProvider(repository);
  });

  tearDown(() {
    provider.dispose();
  });

  test('a query shorter than 3 characters clears results without calling the repository', () async {
    await provider.search('do');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(provider.results, isEmpty);
    verifyNever(() => repository.searchMedications(any()));
  });

  test('debounces and returns matching results after 300ms', () async {
    when(() => repository.searchMedications('dolip')).thenAnswer(
      (_) async => PaginatedResponse(
        items: [MedicationSearchResult(externalId: 'e1', name: 'Doliprane')],
        page: 1,
        limit: 20,
        total: 1,
      ),
    );

    await provider.search('dolip');
    expect(provider.isSearching, isFalse); // debounce timer hasn't fired yet

    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(provider.results, hasLength(1));
    expect(provider.isSearching, isFalse);
  });

  test('a later query cancels the pending debounce for the earlier one', () async {
    when(() => repository.searchMedications('doa')).thenAnswer(
      (_) async => PaginatedResponse(items: [], page: 1, limit: 20, total: 0),
    );
    when(() => repository.searchMedications('dolip')).thenAnswer(
      (_) async => PaginatedResponse(
        items: [MedicationSearchResult(externalId: 'e1', name: 'Doliprane')],
        page: 1,
        limit: 20,
        total: 1,
      ),
    );

    await provider.search('doa');
    await provider.search('dolip');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    verifyNever(() => repository.searchMedications('doa'));
    expect(provider.results, hasLength(1));
  });

  test('maps a 401/403 error to a session-expired message', () async {
    when(() => repository.searchMedications('dolip')).thenThrow(Exception('401 Unauthorized'));

    await provider.search('dolip');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(provider.error, contains('Session expirée'));
  });

  test('clear() cancels pending searches and resets state', () async {
    when(() => repository.searchMedications(any())).thenAnswer(
      (_) async => PaginatedResponse(items: [], page: 1, limit: 20, total: 0),
    );

    await provider.search('dolip');
    provider.clear();
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(provider.results, isEmpty);
    expect(provider.isSearching, isFalse);
    verifyNever(() => repository.searchMedications(any()));
  });
}
