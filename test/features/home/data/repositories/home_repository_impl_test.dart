import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:corevia_mobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:corevia_mobile/networking/api_service.dart';

import '../../../../support/fake_secure_storage.dart';

void main() {
  late HomeRepositoryImpl repository;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test.local');
  });

  setUp(() {
    installFakeSecureStorage()['auth_token'] = 'token';
    repository = HomeRepositoryImpl();
  });

  tearDown(() {
    ApiService.debugResetClient();
  });

  test('builds HomeData from the /me user + stats payload', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.url.path, '/api/me');
        return http.Response(
          jsonEncode({
            'user': {'name': 'Jane', 'image': 'img.png'},
            'alertsCount': 2,
            'stats': {
              'appointmentsThisMonth': 3,
              'completedAppointments': 1,
              'pendingAppointments': 2,
              'medicationAdherenceRate': '80',
            },
          }),
          200,
        );
      }),
    );

    final data = await repository.getHomeData();

    expect(data.userName, 'Jane');
    expect(data.userImage, 'img.png');
    expect(data.alertsCount, 2);
    expect(data.appointmentsThisMonth, 3);
    expect(data.medicationAdherenceRate, 80);
  });

  test('falls back to safe defaults when the request fails', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async => http.Response('boom', 500)),
    );

    final data = await repository.getHomeData();

    expect(data.userName, 'Utilisateur');
    expect(data.alertsCount, 0);
    expect(data.medicationAdherenceRate, 0);
  });

  test('falls back to safe defaults when the response shape is invalid', () async {
    ApiService.debugOverrideClient(
      MockClient((request) async => http.Response(jsonEncode(['not', 'a', 'map']), 200)),
    );

    final data = await repository.getHomeData();

    expect(data.userName, 'Utilisateur');
  });
}
