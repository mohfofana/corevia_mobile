import 'package:flutter/foundation.dart';

import '../../../../networking/api_service.dart';
import '../../../../networking/routes/user_routes.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  @override
  Future<User> fetchCurrentUser() async {
    final meResponse = await ApiService.authGet(UserRoutes.me());

    debugPrint('=== USER REPOSITORY DEBUG ===');
    debugPrint('/api/me response: $meResponse');

    if (meResponse is Map<String, dynamic>) {
      final rawData = meResponse['user'] ?? meResponse;
      debugPrint('/api/me rawData: $rawData');
      if (rawData is Map<String, dynamic>) {
        return User.fromJson(Map<String, dynamic>.from(rawData));
      }
    }

    throw Exception('Impossible de recuperer les donnees utilisateur');
  }

  @override
  Future<User> updateUser(String userId, Map<String, dynamic> data) async {
    final response = await ApiService.authPatch(UserRoutes.me(), data);

    if (response is Map<String, dynamic>) {
      final userData = response['user'] ?? response;
      if (userData is Map<String, dynamic>) {
        return User.fromJson(userData);
      }
    }

    throw Exception('Erreur lors de la mise a jour du profil');
  }
}
