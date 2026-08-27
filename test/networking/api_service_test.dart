import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:corevia_mobile/networking/api_service.dart';

import '../support/fake_secure_storage.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test.local');
  });

  tearDown(() {
    ApiService.debugResetClient();
  });

  group('unauthenticated requests', () {
    test('get() decodes a JSON body on 2xx', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/ping');
          return http.Response(jsonEncode({'ok': true}), 200);
        }),
      );

      final result = await ApiService.get('/ping');

      expect(result, {'ok': true});
    });

    test('get() throws on a non-2xx status', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async => http.Response('boom', 500)),
      );

      expect(() => ApiService.get('/ping'), throwsException);
    });

    test('post() sends the JSON-encoded body', () async {
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(jsonDecode(request.body), {'email': 'a@b.com'});
          return http.Response(jsonEncode({'token': 'tok'}), 201);
        }),
      );

      final result = await ApiService.post('/login', {'email': 'a@b.com'});

      expect(result, {'token': 'tok'});
    });
  });

  group('authenticated requests', () {
    test('authGet() attaches the stored Bearer token', () async {
      installFakeSecureStorage()['auth_token'] = 'secret-token';
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer secret-token');
          return http.Response(jsonEncode({'user': 'me'}), 200);
        }),
      );

      final result = await ApiService.authGet('/me');

      expect(result, {'user': 'me'});
    });

    test('authGet() sends an empty Bearer token when none is stored', () async {
      installFakeSecureStorage();
      ApiService.debugOverrideClient(
        MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer ');
          return http.Response(jsonEncode({}), 200);
        }),
      );

      await ApiService.authGet('/me');
    });
  });
}
