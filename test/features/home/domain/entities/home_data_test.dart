import 'package:corevia_mobile/features/home/domain/entities/home_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomeData exposes the constructor fields as-is', () {
    const data = HomeData(
      title: 'Bonjour',
      description: 'Bienvenue',
      userName: 'Jane',
      userImage: 'img.png',
      alertsCount: 2,
      appointmentsThisMonth: 3,
      completedAppointments: 1,
      pendingAppointments: 2,
      medicationAdherenceRate: 80,
    );

    expect(data.title, 'Bonjour');
    expect(data.userName, 'Jane');
    expect(data.userImage, 'img.png');
    expect(data.alertsCount, 2);
    expect(data.appointmentsThisMonth, 3);
    expect(data.completedAppointments, 1);
    expect(data.pendingAppointments, 2);
    expect(data.medicationAdherenceRate, 80);
  });
}
