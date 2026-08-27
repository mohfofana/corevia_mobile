import 'package:corevia_mobile/features/account/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User.fromJson', () {
    test('parses all fields', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Jane Doe',
        'email': 'jane@doe.com',
        'image': 'img.png',
        'phone': '0102030405',
        'gender': 'F',
        'dateOfBirth': '1990-01-01',
        'address': '1 rue de Paris',
      });

      expect(user.id, '1');
      expect(user.name, 'Jane Doe');
      expect(user.email, 'jane@doe.com');
      expect(user.image, 'img.png');
      expect(user.phone, '0102030405');
      expect(user.gender, 'F');
      expect(user.dateOfBirth, '1990-01-01');
      expect(user.address, '1 rue de Paris');
    });

    test('defaults missing required fields to empty strings and optional to null', () {
      final user = User.fromJson(const {});

      expect(user.id, '');
      expect(user.name, '');
      expect(user.email, '');
      expect(user.image, isNull);
      expect(user.phone, isNull);
    });
  });

  group('User.toJson', () {
    test('omits null optional fields', () {
      const user = User(id: '1', name: 'Jane', email: 'jane@doe.com');

      expect(user.toJson(), {'id': '1', 'name': 'Jane', 'email': 'jane@doe.com'});
    });

    test('includes optional fields when present', () {
      const user = User(
        id: '1',
        name: 'Jane',
        email: 'jane@doe.com',
        phone: '0102030405',
      );

      expect(user.toJson(), {
        'id': '1',
        'name': 'Jane',
        'email': 'jane@doe.com',
        'phone': '0102030405',
      });
    });
  });

  group('User.copyWith', () {
    test('overrides only the given fields', () {
      const user = User(id: '1', name: 'Jane', email: 'jane@doe.com');

      final updated = user.copyWith(name: 'Janet');

      expect(updated.name, 'Janet');
      expect(updated.id, '1');
      expect(updated.email, 'jane@doe.com');
    });
  });

  group('firstName / lastName', () {
    test('splits a multi-word name', () {
      const user = User(id: '1', name: 'Jane Marie Doe', email: 'a@b.com');

      expect(user.firstName, 'Jane');
      expect(user.lastName, 'Marie Doe');
    });

    test('handles a single-word name', () {
      const user = User(id: '1', name: 'Jane', email: 'a@b.com');

      expect(user.firstName, 'Jane');
      expect(user.lastName, '');
    });
  });
}
