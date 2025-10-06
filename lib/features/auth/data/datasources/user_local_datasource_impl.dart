import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/user.dart';
import '../../../../core/errors/exceptions.dart';
import 'user_local_datasource.dart';

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final SharedPreferences sharedPreferences;

  UserLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveUser(User user) async {
    try {
      final userJson = jsonEncode({
        'id': user.id,
        'name': user.name,
        'avatar': user.avatar,
        'isOnline': user.isOnline,
        'lastSeen': user.lastSeen?.toIso8601String(),
      });
      
      await sharedPreferences.setString('current_user', userJson);
      
      // Also save to users list
      final users = await getAllUsers();
      users.removeWhere((u) => u.id == user.id);
      users.add(user);
      await _saveUsersList(users);
    } catch (e) {
      throw CacheException(message: 'Failed to save user: ${e.toString()}');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final userJson = sharedPreferences.getString('current_user');
      if (userJson == null) return null;
      
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User(
        id: userMap['id'] as String,
        name: userMap['name'] as String,
        avatar: userMap['avatar'] as String?,
        isOnline: userMap['isOnline'] as bool? ?? false,
        lastSeen: userMap['lastSeen'] != null 
            ? DateTime.parse(userMap['lastSeen'] as String)
            : null,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<List<User>> getAllUsers() async {
    try {
      final usersJson = sharedPreferences.getString('users_list');
      if (usersJson == null) return [];
      
      final usersList = jsonDecode(usersJson) as List<dynamic>;
      return usersList.map((userMap) {
        return User(
          id: userMap['id'] as String,
          name: userMap['name'] as String,
          avatar: userMap['avatar'] as String?,
          isOnline: userMap['isOnline'] as bool? ?? false,
          lastSeen: userMap['lastSeen'] != null 
              ? DateTime.parse(userMap['lastSeen'] as String)
              : null,
        );
      }).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get all users: ${e.toString()}');
    }
  }

  @override
  Future<User?> getUserById(String id) async {
    try {
      final users = await getAllUsers();
      return users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    try {
      final users = await getAllUsers();
      return users.where((user) =>
          user.name.toLowerCase().contains(query.toLowerCase())).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to search users: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUser(User user) async {
    try {
      await saveUser(user);
    } catch (e) {
      throw CacheException(message: 'Failed to update user: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      final users = await getAllUsers();
      users.removeWhere((user) => user.id == id);
      await _saveUsersList(users);
      
      // If deleting current user, clear current user
      final currentUser = await getCurrentUser();
      if (currentUser?.id == id) {
        await sharedPreferences.remove('current_user');
      }
    } catch (e) {
      throw CacheException(message: 'Failed to delete user: ${e.toString()}');
    }
  }

  @override
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      final users = await getAllUsers();
      final userIndex = users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        users[userIndex] = users[userIndex].copyWith(
          isOnline: isOnline,
          lastSeen: DateTime.now(),
        );
        await _saveUsersList(users);
      }
      
      // Update current user if it's the same user
      final currentUser = await getCurrentUser();
      if (currentUser?.id == userId) {
        await saveUser(currentUser!.copyWith(
          isOnline: isOnline,
          lastSeen: DateTime.now(),
        ));
      }
    } catch (e) {
      throw CacheException(message: 'Failed to update online status: ${e.toString()}');
    }
  }

  Future<void> _saveUsersList(List<User> users) async {
    final usersJson = jsonEncode(users.map((user) => {
      'id': user.id,
      'name': user.name,
      'avatar': user.avatar,
      'isOnline': user.isOnline,
      'lastSeen': user.lastSeen?.toIso8601String(),
    }).toList());
    
    await sharedPreferences.setString('users_list', usersJson);
  }
}
