import 'package:corevia_mobile/features/auth/domain/models/login_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LoginModel.toJson serializes email and password', () {
    final model = LoginModel(email: 'jane@doe.com', password: 'secret');

    expect(model.toJson(), {'email': 'jane@doe.com', 'password': 'secret'});
  });
}
