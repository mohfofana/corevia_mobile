import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:corevia_mobile/features/account/data/repositories/user_repository_impl.dart';
import 'package:corevia_mobile/networking/api_service.dart';

import '../../../../support/fake_secure_storage.dart';

void main() {
  late UserRepositoryImpl repository;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test.local');
  });

  setUp(() {
    installFakeSecureStorage()['auth_token'] = 'token';
    repository = UserRepositoryImpl();
  });

  tearDown(() {
    ApiService.debugResetClient();
  });

  group('fetchCurrentUser', () {
    test('parses a {user: {...}} response', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.url.path, '/api/me');
          return http.Response(
            jsonEncode({'user': {'id': '1', 'name': 'Jane', 'email': 'jane@doe.com'}}),
            200,
          );
        }),
      );

      final user = await repository.fetchCurrentUser();

      expect(user.name, 'Jane');
    });

    test('falls back to the raw payload when there is no "user" key', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          return http.Response(jsonEncode({'id': '1', 'name': 'Jane', 'email': 'jane@doe.com'}), 200);
        }),
      );

      final user = await repository.fetchCurrentUser();

      expect(user.name, 'Jane');
    });

    test('throws when the response has no usable payload', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async => http.Response(jsonEncode(<String, dynamic>{'user': 'nope'}), 200)),
      );

      expect(() => repository.fetchCurrentUser(), throwsException);
    });
  });

  group('updateUser', () {
    test('PATCHes and parses the updated user', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(request.url.path, '/api/me');
          return http.Response(jsonEncode({'user': {'id': '1', 'name': 'Janet', 'email': 'jane@doe.com'}}), 200);
        }),
      );

      final user = await repository.updateUser('1', {'name': 'Janet'});

      expect(user.name, 'Janet');
    });

    test('throws when the response has no usable payload', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async => http.Response(jsonEncode(<String, dynamic>{'user': 'nope'}), 200)),
      );

      expect(() => repository.updateUser('1', {}), throwsException);
    });
  });
}
