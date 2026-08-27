import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/intake.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/medication_schedule.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/paginated_response.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/patient_medication.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/today_intakes.dart';
import 'package:corevia_mobile/features/pillbox/domain/repositories/pillbox_repository.dart';
import 'package:corevia_mobile/features/pillbox/presentation/providers/pillbox_provider.dart';

class MockPillboxRepository extends Mock implements PillboxRepository {}

Intake _intake({String id = 'i1', String status = 'PENDING'}) => Intake(
      id: id,
      patientMedicationId: 'pm1',
      scheduleId: 's1',
      medicationName: 'Doliprane',
      scheduledTime: '08:00',
      intakeMoment: 'MORNING',
      status: status,
    );

PatientMedication _medication({String id = 'pm1'}) => PatientMedication(
      id: id,
      patientId: 'p1',
      medicationName: 'Doliprane',
      startDate: DateTime(2026, 1, 1),
      isActive: true,
    );

void main() {
  late MockPillboxRepository repository;
  late PillboxProvider provider;

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() {
    repository = MockPillboxRepository();
    provider = PillboxProvider(repository);
  });

  group('loadTodayIntakes', () {
    test('populates todayIntakes and computes the badge status', () async {
      when(() => repository.getTodayIntakes()).thenAnswer(
        (_) async => TodayIntakes(date: DateTime(2026, 1, 1), intakes: [_intake(status: 'TAKEN')]),
      );

      await provider.loadTodayIntakes();

      expect(provider.intakes, hasLength(1));
      expect(provider.todayBadgeStatus, 'allTaken');
      expect(provider.error, isNull);
    });

    test('sets an error on failure', () async {
      when(() => repository.getTodayIntakes()).thenThrow(Exception('boom'));

      await provider.loadTodayIntakes();

      expect(provider.error, isNotNull);
    });
  });

  group('loadMedications / loadMoreMedications', () {
    test('loads the first page and reports hasMore', () async {
      when(() => repository.getMyMedications(page: 1, limit: 20)).thenAnswer(
        (_) async => PaginatedResponse(items: [_medication()], page: 1, limit: 20, total: 2),
      );

      await provider.loadMedications();

      expect(provider.medications, hasLength(1));
      expect(provider.hasMore, isTrue);
    });

    test('loadMoreMedications appends the next page', () async {
      when(() => repository.getMyMedications(page: 1, limit: 20)).thenAnswer(
        (_) async => PaginatedResponse(items: [_medication(id: 'pm1')], page: 1, limit: 20, total: 2),
      );
      when(() => repository.getMyMedications(page: 2, limit: 20)).thenAnswer(
        (_) async => PaginatedResponse(items: [_medication(id: 'pm2')], page: 2, limit: 20, total: 2),
      );

      await provider.loadMedications();
      await provider.loadMoreMedications();

      expect(provider.medications.map((m) => m.id), ['pm1', 'pm2']);
      expect(provider.hasMore, isFalse);
    });

    test('loadMoreMedications is a no-op when there is nothing more', () async {
      when(() => repository.getMyMedications(page: 1, limit: 20)).thenAnswer(
        (_) async => PaginatedResponse(items: [_medication()], page: 1, limit: 20, total: 1),
      );

      await provider.loadMedications();
      await provider.loadMoreMedications();

      verifyNever(() => repository.getMyMedications(page: 2, limit: 20));
    });
  });

  group('markIntakeTaken / markIntakeSkipped', () {
    test('updates the local intake status and badge on markIntakeTaken', () async {
      when(() => repository.getTodayIntakes()).thenAnswer(
        (_) async => TodayIntakes(date: DateTime(2026, 1, 1), intakes: [_intake()]),
      );
      when(() => repository.markIntakeTaken(any(), notes: any(named: 'notes')))
          .thenAnswer((_) async {});

      await provider.loadTodayIntakes();
      await provider.markIntakeTaken('i1');

      expect(provider.intakes.first.status, 'TAKEN');
      expect(provider.todayBadgeStatus, 'allTaken');
    });

    test('sets an error when markIntakeSkipped fails', () async {
      when(() => repository.getTodayIntakes()).thenAnswer(
        (_) async => TodayIntakes(date: DateTime(2026, 1, 1), intakes: [_intake()]),
      );
      when(() => repository.markIntakeSkipped(any(), notes: any(named: 'notes')))
          .thenThrow(Exception('boom'));

      await provider.loadTodayIntakes();
      await provider.markIntakeSkipped('i1');

      expect(provider.error, isNotNull);
      expect(provider.intakes.first.status, 'PENDING');
    });
  });

  group('createMedication / updateMedication / deleteMedication', () {
    test('createMedication prepends the new medication and bumps total', () async {
      when(() => repository.createMedication(any())).thenAnswer((_) async => _medication(id: 'pm2'));
      when(() => repository.getTodayIntakes()).thenAnswer(
        (_) async => TodayIntakes(date: DateTime(2026, 1, 1), intakes: const []),
      );

      await provider.createMedication({'medicationName': 'Doliprane'});

      expect(provider.medications.first.id, 'pm2');
      expect(provider.total, 1);
    });

    test('createMedication rethrows on failure', () async {
      when(() => repository.createMedication(any())).thenThrow(Exception('boom'));

      expect(() => provider.createMedication({}), throwsException);
    });

    test('updateMedication replaces the matching medication', () async {
      when(() => repository.getMyMedications(page: 1, limit: 20)).thenAnswer(
        (_) async => PaginatedResponse(items: [_medication()], page: 1, limit: 20, total: 1),
      );
      await provider.loadMedications();

      final updated = PatientMedication(
        id: 'pm1',
        patientId: 'p1',
        medicationName: 'Doliprane 1000',
        startDate: DateTime(2026, 1, 1),
        isActive: true,
      );
      when(() => repository.updateMedication('pm1', any())).thenAnswer((_) async => updated);

      await provider.updateMedication('pm1', {'medicationName': 'Doliprane 1000'});

      expect(provider.medications.first.medicationName, 'Doliprane 1000');
    });

    test('deleteMedication removes the medication and decrements total', () async {
      when(() => repository.getMyMedications(page: 1, limit: 20)).thenAnswer(
        (_) async => PaginatedResponse(items: [_medication()], page: 1, limit: 20, total: 1),
      );
      await provider.loadMedications();

      when(() => repository.deleteMedication('pm1')).thenAnswer((_) async {});
      when(() => repository.getTodayIntakes()).thenAnswer(
        (_) async => TodayIntakes(date: DateTime(2026, 1, 1), intakes: const []),
      );

      await provider.deleteMedication('pm1');

      expect(provider.medications, isEmpty);
      expect(provider.total, 0);
    });
  });

  group('createSchedule / updateSchedule / deleteSchedule', () {
    test('createSchedule appends the schedule to its medication', () async {
      when(() => repository.getMyMedications(page: 1, limit: 20)).thenAnswer(
        (_) async => PaginatedResponse(items: [_medication()], page: 1, limit: 20, total: 1),
      );
      await provider.loadMedications();

      final schedule = MedicationSchedule(
        id: 's1',
        patientMedicationId: 'pm1',
        intakeTime: '08:00',
        intakeMoment: 'MORNING',
        weekday: 1,
        quantity: 1,
      );
      when(() => repository.createSchedule(any())).thenAnswer((_) async => schedule);

      await provider.createSchedule({'intakeTime': '08:00'});

      expect(provider.medications.first.schedules, [schedule]);
    });
  });

  group('history', () {
    test('loadIntakesForDate caches the result and does not re-fetch', () async {
      final date = DateTime(2026, 1, 5);
      when(() => repository.getIntakesForDate(any())).thenAnswer(
        (_) async => TodayIntakes(date: date, intakes: [_intake()]),
      );

      await provider.loadIntakesForDate(date);
      await provider.loadIntakesForDate(date);

      verify(() => repository.getIntakesForDate(any())).called(1);
    });

    test('loadMonthIntakes merges the compliance map', () async {
      when(() => repository.getIntakeHistory(from: any(named: 'from'), to: any(named: 'to')))
          .thenAnswer((_) async => {'2026-01-01': true, '2026-01-02': false});

      await provider.loadMonthIntakes(DateTime(2026, 1, 15));

      expect(provider.getComplianceForDate(DateTime(2026, 1, 1)), isTrue);
      expect(provider.getComplianceForDate(DateTime(2026, 1, 2)), isFalse);
    });
  });
}
