import 'package:corevia_mobile/features/auth/domain/models/register_model.dart';
import 'package:flutter_test/flutter_test.dart';

RegisterModel _valid({
  String firstName = 'Jane',
  String lastName = 'Doe',
  String email = 'jane@doe.com',
  String password = 'Abcd1234!',
  String? confirmPassword,
}) {
  return RegisterModel(
    firstName: firstName,
    lastName: lastName,
    email: email,
    password: password,
    confirmPassword: confirmPassword ?? password,
  );
}

void main() {
  group('RegisterModel validation', () {
    test('accepts valid data', () {
      expect(() => _valid(), returnsNormally);
    });

    test('rejects a first name that is too short', () {
      expect(() => _valid(firstName: 'J'), throwsA(isA<ArgumentError>()));
    });

    test('rejects a last name that is too short', () {
      expect(() => _valid(lastName: 'D'), throwsA(isA<ArgumentError>()));
    });

    test('rejects an invalid email', () {
      expect(() => _valid(email: 'not-an-email'), throwsA(isA<ArgumentError>()));
    });

    test('rejects a password shorter than 8 characters', () {
      expect(
        () => _valid(password: 'Ab1!', confirmPassword: 'Ab1!'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a password missing an uppercase letter', () {
      expect(
        () => _valid(password: 'abcd1234!', confirmPassword: 'abcd1234!'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a password missing a lowercase letter', () {
      expect(
        () => _valid(password: 'ABCD1234!', confirmPassword: 'ABCD1234!'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a password missing a digit', () {
      expect(
        () => _valid(password: 'Abcdefgh!', confirmPassword: 'Abcdefgh!'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a password missing a special character', () {
      expect(
        () => _valid(password: 'Abcd1234', confirmPassword: 'Abcd1234'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects mismatched password confirmation', () {
      expect(
        () => _valid(password: 'Abcd1234!', confirmPassword: 'Different1!'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('RegisterModel.fromJson / toJson', () {
    test('round-trips through JSON', () {
      final model = RegisterModel.fromJson({
        'firstName': 'Jane',
        'lastName': 'Doe',
        'email': 'jane@doe.com',
        'password': 'Abcd1234!',
        'confirmPassword': 'Abcd1234!',
      });

      expect(model.toJson(), {
        'firstName': 'Jane',
        'lastName': 'Doe',
        'email': 'jane@doe.com',
        'password': 'Abcd1234!',
        'confirmPassword': 'Abcd1234!',
      });
    });
  });

  group('RegisterModel equality', () {
    test('two models with the same fields are equal', () {
      expect(_valid(), _valid());
    });

    test('models with different fields are not equal', () {
      expect(_valid(), isNot(_valid(firstName: 'John')));
    });
  });
}
