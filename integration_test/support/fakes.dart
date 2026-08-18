import 'package:corevia_mobile/features/account/domain/entities/user.dart';
import 'package:corevia_mobile/features/account/domain/repositories/user_repository.dart';
import 'package:corevia_mobile/features/booking/domain/entities/appointment.dart';
import 'package:corevia_mobile/features/booking/domain/entities/available_slots.dart';
import 'package:corevia_mobile/features/booking/domain/entities/doctor.dart';
import 'package:corevia_mobile/features/booking/domain/repositories/booking_repository.dart';
import 'package:corevia_mobile/features/home/domain/entities/home_data.dart';
import 'package:corevia_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/intake.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/medication_schedule.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/medication_search_result.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/paginated_response.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/patient_medication.dart';
import 'package:corevia_mobile/features/pillbox/domain/entities/today_intakes.dart';
import 'package:corevia_mobile/features/pillbox/domain/repositories/pillbox_repository.dart';

/// Hand-written test doubles used by the functional (integration_test)
/// journeys. They return fixed, canned data instead of hitting the network,
/// so each journey exercises the real widget tree (screens + providers +
/// router) against a scripted data layer.

class FakeBookingRepository implements BookingRepository {
  static const doctor = Doctor(
    id: 'd1',
    userId: 'u1',
    specialty: 'Cardiologie',
    address: '1 rue de la Santé',
    city: 'Paris',
    name: 'Dr House',
  );

  @override
  Future<PaginatedResponse<Doctor>> listDoctors({
    String? specialty,
    String? city,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    return PaginatedResponse(items: [doctor], page: 1, limit: limit, total: 1);
  }

  @override
  Future<AvailableSlots> getAvailableSlots({
    required String doctorId,
    required String date,
  }) async {
    return AvailableSlots(doctorId: doctorId, date: date, slots: const ['09:00', '10:00']);
  }

  @override
  Future<Appointment> createAppointment({
    required String doctorId,
    required String date,
    required String time,
    String? reason,
  }) async {
    return Appointment(
      id: 'a1',
      doctorId: doctorId,
      patientId: 'p1',
      date: date,
      time: time,
      status: 'pending',
      reason: reason,
    );
  }

  @override
  Future<PaginatedResponse<Appointment>> listMyAppointments({
    String? status,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
    String sort = 'dateDesc',
  }) async {
    return PaginatedResponse(items: const [], page: 1, limit: limit, total: 0);
  }

  @override
  Future<Appointment> getAppointmentDetail(String id) {
    throw UnimplementedError('not used by the functional journeys');
  }
}

class FakePillboxRepository implements PillboxRepository {
  Intake pendingIntake = Intake(
    id: 'i1',
    patientMedicationId: 'pm1',
    scheduleId: 's1',
    medicationName: 'Doliprane',
    medicationForm: 'comprimé',
    scheduledTime: '08:00',
    intakeMoment: 'MORNING',
    quantity: 1,
    unit: 'cp',
    status: 'PENDING',
  );

  @override
  Future<PaginatedResponse<PatientMedication>> getMyMedications({
    int page = 1,
    int limit = 20,
    bool? isActive,
  }) async {
    return PaginatedResponse(items: const [], page: 1, limit: limit, total: 0);
  }

  @override
  Future<TodayIntakes> getTodayIntakes() async {
    return TodayIntakes(date: DateTime.now(), intakes: [pendingIntake]);
  }

  @override
  Future<TodayIntakes> getIntakesForDate(DateTime date) async {
    return TodayIntakes(date: date, intakes: const []);
  }

  @override
  Future<void> markIntakeTaken(String intakeId, {String? notes}) async {}

  @override
  Future<void> markIntakeSkipped(String intakeId, {String? notes}) async {}

  @override
  Future<Map<String, bool?>> getIntakeHistory({
    required DateTime from,
    required DateTime to,
  }) async {
    return {};
  }

  @override
  Future<Intake> getIntakeByIdFromToday(String intakeId) async {
    if (intakeId == pendingIntake.id) return pendingIntake;
    throw StateError('Intake introuvable: $intakeId');
  }

  @override
  Future<PatientMedication> createMedication(Map<String, dynamic> body) {
    throw UnimplementedError('not used by the functional journeys');
  }

  @override
  Future<PatientMedication> getMedicationDetail(String id) {
    throw UnimplementedError('not used by the functional journeys');
  }

  @override
  Future<PatientMedication> updateMedication(String id, Map<String, dynamic> body) {
    throw UnimplementedError('not used by the functional journeys');
  }

  @override
  Future<void> deleteMedication(String id) {
    throw UnimplementedError('not used by the functional journeys');
  }

  @override
  Future<MedicationSchedule> createSchedule(Map<String, dynamic> body) {
    throw UnimplementedError('not used by the functional journeys');
  }

  @override
  Future<MedicationSchedule> updateSchedule(String id, Map<String, dynamic> body) {
    throw UnimplementedError('not used by the functional journeys');
  }

  @override
  Future<void> deleteSchedule(String id) {
    throw UnimplementedError('not used by the functional journeys');
  }

  @override
  Future<PaginatedResponse<MedicationSearchResult>> searchMedications(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    return PaginatedResponse(items: const [], page: 1, limit: limit, total: 0);
  }

  @override
  Future<MedicationSearchResult?> getMedicationByCode({
    String? cis,
    String? cip,
    String? externalId,
  }) async {
    return null;
  }
}

class FakeUserRepository implements UserRepository {
  static const user = User(id: '1', name: 'Jane Doe', email: 'jane@doe.com');

  @override
  Future<User> fetchCurrentUser() async => user;

  @override
  Future<User> updateUser(String userId, Map<String, dynamic> data) async => user;
}

class FakeHomeRepository implements HomeRepository {
  @override
  Future<HomeData> getHomeData() async {
    return const HomeData(
      title: 'Bienvenue sur CoreVia',
      description: 'Votre application de gestion CoreVia',
      userName: 'Jane',
      userImage: null,
      alertsCount: 0,
      appointmentsThisMonth: 0,
      completedAppointments: 0,
      pendingAppointments: 0,
      medicationAdherenceRate: 0,
    );
  }
}
