import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:corevia_mobile/features/booking/domain/entities/appointment.dart';
import 'package:corevia_mobile/features/booking/domain/entities/available_slots.dart';
import 'package:corevia_mobile/features/booking/domain/entities/doctor.dart';
import 'package:corevia_mobile/features/booking/domain/repositories/booking_repository.dart';
import 'package:corevia_mobile/features/booking/presentation/providers/booking_provider.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/paginated_response.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

const _doctor = Doctor(id: 'd1', userId: 'u1', specialty: 'Cardio', address: 'a', city: 'Paris', name: 'Dr House');
const _appointment = Appointment(
  id: 'a1',
  doctorId: 'd1',
  patientId: 'p1',
  date: '2026-01-01',
  time: '09:00',
  status: 'pending',
);

void main() {
  late MockBookingRepository repository;
  late BookingProvider provider;

  setUp(() {
    repository = MockBookingRepository();
    provider = BookingProvider(repository);
  });

  group('loadDoctors', () {
    test('populates doctors and total on success', () async {
      when(() => repository.listDoctors(
            specialty: any(named: 'specialty'),
            city: any(named: 'city'),
            search: any(named: 'search'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer(
        (_) async => PaginatedResponse(items: [_doctor], page: 1, limit: 20, total: 1),
      );

      await provider.loadDoctors();

      expect(provider.doctors, [_doctor]);
      expect(provider.doctorsTotal, 1);
      expect(provider.error, isNull);
      expect(provider.isLoadingDoctors, isFalse);
    });

    test('sets an error message and clears loading on failure', () async {
      when(() => repository.listDoctors(
            specialty: any(named: 'specialty'),
            city: any(named: 'city'),
            search: any(named: 'search'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenThrow(Exception('network down'));

      await provider.loadDoctors();

      expect(provider.error, isNotNull);
      expect(provider.doctors, isEmpty);
      expect(provider.isLoadingDoctors, isFalse);
    });
  });

  group('loadAvailableSlots', () {
    test('populates slots on success', () async {
      when(() => repository.getAvailableSlots(doctorId: any(named: 'doctorId'), date: any(named: 'date')))
          .thenAnswer((_) async => const AvailableSlots(doctorId: 'd1', date: '2026-01-01', slots: ['09:00']));

      await provider.loadAvailableSlots(doctorId: 'd1', date: '2026-01-01');

      expect(provider.availableSlots, ['09:00']);
    });

    test('clears slots and sets an error on failure', () async {
      when(() => repository.getAvailableSlots(doctorId: any(named: 'doctorId'), date: any(named: 'date')))
          .thenThrow(Exception('boom'));

      await provider.loadAvailableSlots(doctorId: 'd1', date: '2026-01-01');

      expect(provider.availableSlots, isEmpty);
      expect(provider.error, isNotNull);
    });
  });

  group('createAppointment', () {
    test('returns the created appointment on success', () async {
      when(() => repository.createAppointment(
            doctorId: any(named: 'doctorId'),
            date: any(named: 'date'),
            time: any(named: 'time'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => _appointment);

      final result = await provider.createAppointment(doctorId: 'd1', date: '2026-01-01', time: '09:00');

      expect(result, _appointment);
      expect(provider.isSubmitting, isFalse);
    });

    test('returns null and sets an error on failure', () async {
      when(() => repository.createAppointment(
            doctorId: any(named: 'doctorId'),
            date: any(named: 'date'),
            time: any(named: 'time'),
            reason: any(named: 'reason'),
          )).thenThrow(Exception('boom'));

      final result = await provider.createAppointment(doctorId: 'd1', date: '2026-01-01', time: '09:00');

      expect(result, isNull);
      expect(provider.error, isNotNull);
    });
  });

  group('loadMyAppointments', () {
    test('populates appointments and total on success', () async {
      when(() => repository.listMyAppointments(
            status: any(named: 'status'),
            from: any(named: 'from'),
            to: any(named: 'to'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => PaginatedResponse(items: [_appointment], page: 1, limit: 20, total: 1));

      await provider.loadMyAppointments();

      expect(provider.appointments, [_appointment]);
      expect(provider.appointmentsTotal, 1);
    });

    test('clears appointments and sets an error on failure', () async {
      when(() => repository.listMyAppointments(
            status: any(named: 'status'),
            from: any(named: 'from'),
            to: any(named: 'to'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            sort: any(named: 'sort'),
          )).thenThrow(Exception('boom'));

      await provider.loadMyAppointments();

      expect(provider.appointments, isEmpty);
      expect(provider.error, isNotNull);
    });
  });
}
