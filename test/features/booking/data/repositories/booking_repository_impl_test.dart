import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:corevia_mobile/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:corevia_mobile/networking/api_service.dart';

import '../../../../support/fake_secure_storage.dart';

void main() {
  late BookingRepositoryImpl repository;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test.local');
  });

  setUp(() {
    installFakeSecureStorage()['auth_token'] = 'token';
    repository = BookingRepositoryImpl();
  });

  tearDown(() {
    ApiService.debugResetClient();
  });

  group('listDoctors', () {
    test('parses a flat {items, page, limit, total} response', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.url.path, '/api/doctors');
          return http.Response(
            jsonEncode({
              'items': [
                {'id': 'd1', 'userId': 'u1', 'specialty': 'Cardio', 'address': 'a', 'city': 'Paris', 'name': 'Dr House'},
              ],
              'page': 1,
              'limit': 20,
              'total': 1,
            }),
            200,
          );
        }),
      );

      final result = await repository.listDoctors();

      expect(result.items, hasLength(1));
      expect(result.items.first.name, 'Dr House');
      expect(result.total, 1);
    });

    test('parses a nested {data: {items, ...}} response', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'data': {
                'items': [
                  {'id': 'd1', 'userId': 'u1', 'specialty': 'Cardio', 'address': 'a', 'city': 'Paris', 'name': 'Dr House'},
                ],
                'total': 5,
              },
            }),
            200,
          );
        }),
      );

      final result = await repository.listDoctors();

      expect(result.items, hasLength(1));
      expect(result.total, 5);
    });

    test('parses a {data: [...]} response, defaulting total to item count', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 'd1', 'userId': 'u1', 'specialty': 'Cardio', 'address': 'a', 'city': 'Paris', 'name': 'Dr House'},
                {'id': 'd2', 'userId': 'u2', 'specialty': 'Derma', 'address': 'b', 'city': 'Lyon', 'name': 'Dr Wilson'},
              ],
            }),
            200,
          );
        }),
      );

      final result = await repository.listDoctors();

      expect(result.items, hasLength(2));
      expect(result.total, 2);
    });

    test('forwards non-empty filters as query params', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.url.queryParameters['specialty'], 'Cardio');
          expect(request.url.queryParameters['city'], 'Paris');
          expect(request.url.queryParameters['search'], 'House');
          return http.Response(jsonEncode({'items': []}), 200);
        }),
      );

      await repository.listDoctors(specialty: 'Cardio', city: 'Paris', search: 'House');
    });
  });

  group('getAvailableSlots', () {
    test('parses slots for a doctor/date', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.url.path, '/api/doctors/d1/available-slots');
          expect(request.url.queryParameters['date'], '2026-01-01');
          return http.Response(
            jsonEncode({'doctorId': 'd1', 'date': '2026-01-01', 'slots': ['09:00']}),
            200,
          );
        }),
      );

      final result = await repository.getAvailableSlots(doctorId: 'd1', date: '2026-01-01');

      expect(result.slots, ['09:00']);
    });
  });

  group('createAppointment', () {
    test('posts the payload and parses the created appointment', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/appointments');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['doctorId'], 'd1');
          expect(body['reason'], 'Checkup');
          return http.Response(
            jsonEncode({
              'id': 'a1',
              'doctorId': 'd1',
              'patientId': 'p1',
              'date': '2026-01-01',
              'time': '09:00',
              'status': 'pending',
            }),
            201,
          );
        }),
      );

      final appointment = await repository.createAppointment(
        doctorId: 'd1',
        date: '2026-01-01',
        time: '09:00',
        reason: 'Checkup',
      );

      expect(appointment.id, 'a1');
      expect(appointment.status, 'pending');
    });

    test('omits reason when blank', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body.containsKey('reason'), isFalse);
          return http.Response(
            jsonEncode({
              'id': 'a1',
              'doctorId': 'd1',
              'patientId': 'p1',
              'date': '2026-01-01',
              'time': '09:00',
              'status': 'pending',
            }),
            201,
          );
        }),
      );

      await repository.createAppointment(doctorId: 'd1', date: '2026-01-01', time: '09:00', reason: '  ');
    });
  });

  group('listMyAppointments', () {
    test('parses the appointments list', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.url.path, '/api/appointments');
          return http.Response(
            jsonEncode({
              'items': [
                {'id': 'a1', 'doctorId': 'd1', 'patientId': 'p1', 'date': '2026-01-01', 'time': '09:00', 'status': 'pending'},
              ],
              'total': 1,
            }),
            200,
          );
        }),
      );

      final result = await repository.listMyAppointments();

      expect(result.items, hasLength(1));
    });
  });

  group('getAppointmentDetail', () {
    test('parses a single appointment', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.url.path, '/api/appointments/a1');
          return http.Response(
            jsonEncode({
              'id': 'a1',
              'doctorId': 'd1',
              'patientId': 'p1',
              'date': '2026-01-01',
              'time': '09:00',
              'status': 'confirmed',
            }),
            200,
          );
        }),
      );

      final appointment = await repository.getAppointmentDetail('a1');

      expect(appointment.status, 'confirmed');
    });
  });
}
