import 'package:flutter/foundation.dart';
import 'package:corevia_mobile/networking/api_service.dart';
import 'package:corevia_mobile/networking/routes/user_routes.dart';

import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  @override
  Future<HomeData> getHomeData() async {
    try {
      final meResponse = await ApiService.authGet(UserRoutes.me());
      if (meResponse is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }

      final user = _asMap(meResponse['user'] ?? meResponse);
      final stats = _asMap(meResponse['stats']);

      return HomeData(
        title: 'Welcome to CoreVia',
        description: 'Your CoreVia management app',
        userName: (user['name'] ?? 'User').toString(),
        userImage: user['image']?.toString(),
        alertsCount: _asInt(meResponse['alertsCount']),
        appointmentsThisMonth: _asInt(stats['appointmentsThisMonth']),
        completedAppointments: _asInt(stats['completedAppointments']),
        pendingAppointments: _asInt(stats['pendingAppointments']),
        medicationAdherenceRate: _asInt(stats['medicationAdherenceRate']),
      );
    } catch (e) {
      debugPrint('HomeRepositoryImpl.getHomeData error: $e');
      return const HomeData(
        title: 'Welcome to CoreVia',
        description: 'Your CoreVia management app',
        userName: 'User',
        userImage: null,
        alertsCount: 0,
        appointmentsThisMonth: 0,
        completedAppointments: 0,
        pendingAppointments: 0,
        medicationAdherenceRate: 0,
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return const {};
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
