import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:video_calling_app/utils/constants.dart';

import '../models/user_model.dart';
import '../services/local_storage_service.dart';

class UserRepository {
  Future<List<User>> getUsers({bool forceRefresh = false}) async {
    await LocalStorageService.init();

    if (!forceRefresh && await LocalStorageService.isCacheValid()) {
      final cachedUsers = await LocalStorageService.getCachedUsers();
      if (cachedUsers.isNotEmpty) {
        return cachedUsers;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.endPoint}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final users = jsonList.map((json) => User.fromJson(json)).toList();

        await LocalStorageService.cacheUsers(users);

        return users;
      } else {
        final cachedUsers = await LocalStorageService.getCachedUsers();
        if (cachedUsers.isNotEmpty) {
          return cachedUsers;
        }
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      final cachedUsers = await LocalStorageService.getCachedUsers();
      if (cachedUsers.isNotEmpty) {
        return cachedUsers;
      }
      rethrow;
    }
  }
}
