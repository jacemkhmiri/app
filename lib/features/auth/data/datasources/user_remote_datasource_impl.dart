import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/entities/user.dart';
import '../../../../core/errors/exceptions.dart';
import 'user_remote_datasource.dart';

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  UserRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<User> createUser(String username) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User(
          id: data['id'] as String,
          name: data['username'] as String,
          avatar: data['avatar'] as String?,
          isOnline: data['is_online'] as bool? ?? false,
          lastSeen: data['last_seen'] != null 
              ? DateTime.parse(data['last_seen'] as String)
              : null,
        );
      } else {
        throw ServerException(
          message: 'Failed to create user: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User(
          id: data['id'] as String,
          name: data['username'] as String,
          avatar: data['avatar'] as String?,
          isOnline: data['is_online'] as bool? ?? false,
          lastSeen: data['last_seen'] != null 
              ? DateTime.parse(data['last_seen'] as String)
              : null,
        );
      } else {
        throw ServerException(
          message: 'Failed to get current user: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<List<User>> getAllUsers() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((userData) {
          return User(
            id: userData['id'] as String,
            name: userData['username'] as String,
            avatar: userData['avatar'] as String?,
            isOnline: userData['is_online'] as bool? ?? false,
            lastSeen: userData['last_seen'] != null 
                ? DateTime.parse(userData['last_seen'] as String)
                : null,
          );
        }).toList();
      } else {
        throw ServerException(
          message: 'Failed to get users: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<User> getUserById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User(
          id: data['id'] as String,
          name: data['username'] as String,
          avatar: data['avatar'] as String?,
          isOnline: data['is_online'] as bool? ?? false,
          lastSeen: data['last_seen'] != null 
              ? DateTime.parse(data['last_seen'] as String)
              : null,
        );
      } else {
        throw ServerException(
          message: 'Failed to get user: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/users?search=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((userData) {
          return User(
            id: userData['id'] as String,
            name: userData['username'] as String,
            avatar: userData['avatar'] as String?,
            isOnline: userData['is_online'] as bool? ?? false,
            lastSeen: userData['last_seen'] != null 
                ? DateTime.parse(userData['last_seen'] as String)
                : null,
          );
        }).toList();
      } else {
        throw ServerException(
          message: 'Failed to search users: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<User> updateUser(User user) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/api/users/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': user.name,
          'avatar': user.avatar,
          'is_online': user.isOnline,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User(
          id: data['id'] as String,
          name: data['username'] as String,
          avatar: data['avatar'] as String?,
          isOnline: data['is_online'] as bool? ?? false,
          lastSeen: data['last_seen'] != null 
              ? DateTime.parse(data['last_seen'] as String)
              : null,
        );
      } else {
        throw ServerException(
          message: 'Failed to update user: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/api/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to delete user: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/online-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'is_online': isOnline,
        }),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to update online status: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Network error: ${e.toString()}');
    }
  }
}
