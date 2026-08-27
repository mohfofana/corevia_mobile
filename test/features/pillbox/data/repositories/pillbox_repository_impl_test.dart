import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:corevia_mobile/features/pillbox/data/repositories/pillbox_repository_impl.dart';
import 'package:corevia_mobile/networking/api_service.dart';

import '../../../../support/fake_secure_storage.dart';

Map<String, dynamic> _medicationJson({String id = 'pm1'}) => {
      'id': id,
      'patientId': 'p1',
      'medicationName': 'Doliprane',
      'startDate': '2026-01-01T00:00:00.000Z',
      'isActive': true,
    };

void main() {
  late PillboxRepositoryImpl repository;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test.local');
  });

  setUp(() {
    installFakeSecureStorage()['auth_token'] = 'token';
    repository = PillboxRepositoryImpl();
  });

  tearDown(() {
    ApiService.debugResetClient();
  });

  test('getMyMedications parses a paginated list, forwarding isActive', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.url.path, '/api/pillbox');
        expect(request.url.queryParameters['isActive'], 'true');
        return http.Response(
          jsonEncode({'items': [_medicationJson()], 'page': 1, 'limit': 20, 'total': 1}),
          200,
        );
      }),
    );

    final result = await repository.getMyMedications(isActive: true);

    expect(result.items, hasLength(1));
    expect(result.total, 1);
  });

  test('createMedication posts the body and parses the result', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/pillbox');
        return http.Response(jsonEncode(_medicationJson()), 201);
      }),
    );

    final medication = await repository.createMedication({'medicationName': 'Doliprane'});

    expect(medication.id, 'pm1');
  });

  test('getMedicationDetail fetches by id', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.url.path, '/api/pillbox/pm1');
        return http.Response(jsonEncode(_medicationJson()), 200);
      }),
    );

    final medication = await repository.getMedicationDetail('pm1');

    expect(medication.id, 'pm1');
  });

  test('updateMedication PATCHes the body', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/pillbox/pm1');
        return http.Response(jsonEncode(_medicationJson()), 200);
      }),
    );

    await repository.updateMedication('pm1', {'dosageLabel': '1000mg'});
  });

  test('deleteMedication DELETEs by id', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/pillbox/pm1');
        return http.Response('', 200);
      }),
    );

    await repository.deleteMedication('pm1');
  });

  test('getTodayIntakes parses today\'s intakes', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.url.path, '/api/pillbox/today');
        return http.Response(jsonEncode({'date': '2026-01-01', 'intakes': []}), 200);
      }),
    );

    final result = await repository.getTodayIntakes();

    expect(result.intakes, isEmpty);
  });

  test('markIntakeTaken posts optional notes only when present', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.url.path, '/api/pillbox/intakes/i1/taken');
        expect(jsonDecode(request.body), <String, dynamic>{});
        return http.Response('{}', 200);
      }),
    );

    await repository.markIntakeTaken('i1');
  });

  test('markIntakeSkipped includes notes when provided', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.url.path, '/api/pillbox/intakes/i1/skipped');
        expect(jsonDecode(request.body), {'notes': 'forgot'});
        return http.Response('{}', 200);
      }),
    );

    await repository.markIntakeSkipped('i1', notes: 'forgot');
  });

  test('createSchedule / updateSchedule / deleteSchedule hit the schedule routes', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        if (request.method == 'POST') {
          expect(request.url.path, '/api/pillbox/schedules');
          return http.Response(
            jsonEncode({'id': 's1', 'patientMedicationId': 'pm1', 'intakeTime': '08:00', 'intakeMoment': 'MORNING', 'weekday': 1, 'quantity': 1}),
            201,
          );
        }
        if (request.method == 'PATCH') {
          expect(request.url.path, '/api/pillbox/schedules/s1');
          return http.Response(
            jsonEncode({'id': 's1', 'patientMedicationId': 'pm1', 'intakeTime': '09:00', 'intakeMoment': 'MORNING', 'weekday': 1, 'quantity': 1}),
            200,
          );
        }
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/pillbox/schedules/s1');
        return http.Response('', 200);
      }),
    );

    final created = await repository.createSchedule({'intakeTime': '08:00'});
    expect(created.id, 's1');
    final updated = await repository.updateSchedule('s1', {'intakeTime': '09:00'});
    expect(updated.intakeTime, '09:00');
    await repository.deleteSchedule('s1');
  });

  test('searchMedications parses results list', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.url.path, '/api/medications/search');
        expect(request.url.queryParameters['query'], 'dolip');
        return http.Response(
          jsonEncode({
            'items': [
              {'externalId': 'e1', 'name': 'Doliprane'},
            ],
            'total': 1,
          }),
          200,
        );
      }),
    );

    final result = await repository.searchMedications('dolip');

    expect(result.items, hasLength(1));
  });

  group('getMedicationByCode', () {
    test('returns null when no identifier is given', () async {
      final result = await repository.getMedicationByCode();

      expect(result, isNull);
    });

    test('returns null when the API returns null', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async => http.Response('null', 200)),
      );

      final result = await repository.getMedicationByCode(cis: '123');

      expect(result, isNull);
    });

    test('parses the medication when found', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.url.queryParameters['cis'], '123');
          return http.Response(jsonEncode({'externalId': 'e1', 'name': 'Doliprane'}), 200);
        }),
      );

      final result = await repository.getMedicationByCode(cis: '123');

      expect(result?.name, 'Doliprane');
    });
  });

  test('getIntakeByIdFromToday finds the matching intake', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'date': '2026-01-01',
            'intakes': [
              {'id': 'i1', 'patientMedicationId': 'pm1', 'scheduleId': 's1', 'medicationName': 'Doliprane', 'scheduledTime': '08:00', 'intakeMoment': 'MORNING', 'status': 'PENDING'},
            ],
          }),
          200,
        );
      }),
    );

    final intake = await repository.getIntakeByIdFromToday('i1');

    expect(intake.medicationName, 'Doliprane');
  });

  test('getIntakeByIdFromToday throws when the intake is not found', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async => http.Response(jsonEncode({'date': '2026-01-01', 'intakes': []}), 200)),
    );

    expect(() => repository.getIntakeByIdFromToday('missing'), throwsStateError);
  });

  test('getIntakeHistory maps day → allTaken', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.url.path, '/api/pillbox/history');
        return http.Response(
          jsonEncode({
            'days': [
              {'date': '2026-01-01', 'allTaken': true},
              {'date': '2026-01-02', 'allTaken': false},
            ],
          }),
          200,
        );
      }),
    );

    final result = await repository.getIntakeHistory(
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 1, 2),
    );

    expect(result, {'2026-01-01': true, '2026-01-02': false});
  });
}
