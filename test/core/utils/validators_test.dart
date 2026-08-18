import 'package:corevia_mobile/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns error when null or empty', () {
      expect(
        Validators.validateEmail(null),
        'Veuillez entrer votre adresse email',
      );
      expect(
        Validators.validateEmail('   '),
        'Veuillez entrer votre adresse email',
      );
    });

    test('returns error for invalid email', () {
      expect(
        Validators.validateEmail('invalid-email'),
        'Veuillez entrer une adresse email valide',
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
        "Nom d'utilisateur doit contenir au moins 2 caracteres",
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
        'Le mot de passe doit contenir au moins 8 caracteres',
      );
    });

    test('enforces strong rules when required', () {
      expect(
        Validators.validatePassword('abcdefgh', requireStrongRules: true),
        'Le mot de passe doit contenir au moins une majuscule',
      );
      expect(
        Validators.validatePassword('Abcdefgh', requireStrongRules: true),
        'Le mot de passe doit contenir au moins un chiffre',
      );
      expect(
        Validators.validatePassword('Abcdefg1', requireStrongRules: true),
        'Le mot de passe doit contenir au moins un caractere special',
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
