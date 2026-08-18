import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:corevia_mobile/features/home/domain/entities/home_data.dart';
import 'package:corevia_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:corevia_mobile/features/home/presentation/providers/home_provider.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

const _homeData = HomeData(
  title: 'Bonjour',
  description: 'Bienvenue',
  userName: 'Jane',
  userImage: null,
  alertsCount: 0,
  appointmentsThisMonth: 0,
  completedAppointments: 0,
  pendingAppointments: 0,
  medicationAdherenceRate: 0,
);

void main() {
  late MockHomeRepository repository;
  late HomeProvider provider;

  setUp(() {
    repository = MockHomeRepository();
    provider = HomeProvider(repository);
  });

  test('loadHomeData populates homeData on success', () async {
    when(() => repository.getHomeData()).thenAnswer((_) async => _homeData);

    await provider.loadHomeData();

    expect(provider.homeData, _homeData);
    expect(provider.error, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('loadHomeData sets an error on failure', () async {
    when(() => repository.getHomeData()).thenThrow(Exception('boom'));

    await provider.loadHomeData();

    expect(provider.homeData, isNull);
    expect(provider.error, isNotNull);
  });
}
