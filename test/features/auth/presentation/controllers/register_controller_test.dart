import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:corevia_mobile/features/auth/domain/models/register_model.dart';
import 'package:corevia_mobile/features/auth/presentation/controllers/register_controller.dart';
import 'package:corevia_mobile/networking/api_service.dart';

import '../../../../support/fake_secure_storage.dart';

RegisterModel _model() => RegisterModel(
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane@doe.com',
      password: 'Abcd1234!',
      confirmPassword: 'Abcd1234!',
    );

void main() {
  late RegisterController controller;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test.local');
  });

  setUp(() {
    controller = RegisterController();
  });

  tearDown(() {
    ApiService.debugResetClient();
  });

  test('posts the combined name and stores the returned token', () async {
    final data = installFakeSecureStorage();
    ApiService.debugOverrideClient(
      MockClient((request) async {
        expect(request.url.path, '/api/auth/sign-up/email');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Jane Doe');
        expect(body['email'], 'jane@doe.com');
        return http.Response(jsonEncode({'token': 'tok-456'}), 201);
      }),
    );

    final result = await controller.register(_model());

    expect(result, isTrue);
    expect(data['auth_token'], 'tok-456');
  });

  test('returns false when the token is missing', () async {
    installFakeSecureStorage();
    ApiService.debugOverrideClient(
      MockClient((request) async => http.Response(jsonEncode({}), 200)),
    );

    final result = await controller.register(_model());

    expect(result, isFalse);
  });

  test('returns false on an HTTP error', () async {
    installFakeSecureStorage();
    ApiService.debugOverrideClient(
      MockClient((request) async => http.Response('conflict', 409)),
    );

    final result = await controller.register(_model());

    expect(result, isFalse);
  });
}
