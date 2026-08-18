import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corevia_mobile/features/account/domain/entities/user.dart';
import 'package:corevia_mobile/features/account/domain/repositories/user_repository.dart';
import 'package:corevia_mobile/features/account/presentation/providers/user_provider.dart';

class MockUserRepository extends Mock implements UserRepository {}

const _user = User(id: '1', name: 'Jane Doe', email: 'jane@doe.com');

void main() {
  late MockUserRepository repository;
  late UserProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockUserRepository();
    provider = UserProvider(repository);
  });

  group('setUserFromLoginData', () {
    test('builds a User from login payload fields', () async {
      await provider.setUserFromLoginData({
        'id': 1,
        'name': 'Jane Doe',
        'email': 'jane@doe.com',
        'phoneNumber': '0102030405',
      });

      expect(provider.user?.name, 'Jane Doe');
      expect(provider.user?.phone, '0102030405');
    });
  });

  group('loadUser', () {
    test('sets the user from the repository on success', () async {
      when(() => repository.fetchCurrentUser()).thenAnswer((_) async => _user);

      await provider.loadUser();

      expect(provider.user, _user);
      expect(provider.error, isNull);
    });

    test('falls back to the cache and clears the error when a cached user exists', () async {
      await provider.setUserFromLoginData({'id': '1', 'name': 'Jane', 'email': 'jane@doe.com'});
      when(() => repository.fetchCurrentUser()).thenThrow(Exception('network down'));

      await provider.loadUser();

      expect(provider.user, isNotNull);
      expect(provider.error, isNull);
    });

    test('sets an error when the repository fails and there is no cache', () async {
      when(() => repository.fetchCurrentUser()).thenThrow(Exception('network down'));

      await provider.loadUser();

      expect(provider.user, isNull);
      expect(provider.error, isNotNull);
    });
  });

  group('updateUser', () {
    test('returns false when there is no current user', () async {
      final result = await provider.updateUser({'name': 'New name'});

      expect(result, isFalse);
      verifyNever(() => repository.updateUser(any(), any()));
    });

    test('updates the user and returns true on success', () async {
      when(() => repository.fetchCurrentUser()).thenAnswer((_) async => _user);
      await provider.loadUser();

      const updated = User(id: '1', name: 'Janet', email: 'jane@doe.com');
      when(() => repository.updateUser('1', any())).thenAnswer((_) async => updated);

      final result = await provider.updateUser({'name': 'Janet'});

      expect(result, isTrue);
      expect(provider.user?.name, 'Janet');
    });

    test('returns false and sets an error on failure', () async {
      when(() => repository.fetchCurrentUser()).thenAnswer((_) async => _user);
      await provider.loadUser();
      when(() => repository.updateUser('1', any())).thenThrow(Exception('boom'));

      final result = await provider.updateUser({'name': 'Janet'});

      expect(result, isFalse);
      expect(provider.error, isNotNull);
    });
  });

  group('clear', () {
    test('resets the user and error state', () async {
      when(() => repository.fetchCurrentUser()).thenAnswer((_) async => _user);
      await provider.loadUser();

      await provider.clear();

      expect(provider.user, isNull);
      expect(provider.error, isNull);
    });
  });
}
