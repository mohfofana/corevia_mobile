import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:corevia_mobile/features/auth/presentation/controllers/login_controller.dart';
import 'package:corevia_mobile/networking/api_service.dart';

import '../../../../support/fake_secure_storage.dart';

void main() {
  late LoginController controller;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test.local');
  });

  setUp(() {
    controller = LoginController();
  });

  tearDown(() {
    ApiService.debugResetClient();
  });

  test('stores the returned token and returns true on success', () async {
    final data = installFakeSecureStorage();
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.url.path, '/api/auth/sign-in/email');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'jane@doe.com');
        expect(body['password'], 'secret');
        return http.Response(jsonEncode({'token': 'tok-123'}), 200);
      }),
    );

    final result = await controller.login('jane@doe.com', 'secret');

    expect(result, isTrue);
    expect(data['auth_token'], 'tok-123');
  });

  test('returns false and stores nothing when the token is missing', () async {
    installFakeSecureStorage();
    ApiService.debugOverrideClient(
      MockClient((request) async => http.Response(jsonEncode({}), 200)),
    );

    final result = await controller.login('jane@doe.com', 'secret');

    expect(result, isFalse);
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'auth_token'), isNull);
  });

  test('returns false on an HTTP error', () async {
    installFakeSecureStorage();
    ApiService.debugOverrideClient(
      MockClient((request) async => http.Response('unauthorized', 401)),
    );

    final result = await controller.login('jane@doe.com', 'wrong');

    expect(result, isFalse);
  });
}
