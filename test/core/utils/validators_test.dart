import 'package:corevia_mobile/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns error when null or empty', () {
      expect(
        Validators.validateEmail(null),
        'Please enter your email address',
      );
      expect(
        Validators.validateEmail('   '),
        'Please enter your email address',
      );
    });

    test('returns error for invalid email', () {
      expect(
        Validators.validateEmail('invalid-email'),
        'Please enter a valid email address',
      );
    });

    test('returns null for valid email', () {
      expect(Validators.validateEmail('john.doe@mail.com'), isNull);
    });
  });

  group('Validators.validateUsername', () {
    test('enforces min length', () {
      expect(
        Validators.validateUsername('a'),
        'Username must contain at least 2 characters',
      );
    });

    test('returns null for valid username', () {
      expect(Validators.validateUsername('Justin Olyoh'), isNull);
    });
  });

  group('Validators.validatePassword', () {
    test('enforces basic length constraints', () {
      expect(
        Validators.validatePassword('123'),
        'Password must be between 8 and 100 characters long',
      );
    });

    test('enforces strong rules when required', () {
      expect(
        Validators.validatePassword('abcdefgh', requireStrongRules: true),
        'Password must contain at least one uppercase letter',
      );
      expect(
        Validators.validatePassword('Abcdefgh', requireStrongRules: true),
        'Password must contain at least one digit',
      );
      expect(
        Validators.validatePassword('Abcdefg1', requireStrongRules: true),
        'Password must contain at least one special character',
      );
    });

    test('returns null for strong valid password', () {
      expect(
        Validators.validatePassword('Abcd1234!', requireStrongRules: true),
        isNull,
      );
    });
  });
}
