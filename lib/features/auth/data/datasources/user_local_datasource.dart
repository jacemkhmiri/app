import '../../domain/entities/user.dart';

abstract class UserLocalDataSource {
  Future<void> saveUser(User user);
  Future<User?> getCurrentUser();
  Future<List<User>> getAllUsers();
  Future<User?> getUserById(String id);
  Future<List<User>> searchUsers(String query);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String id);
  Future<void> updateOnlineStatus(String userId, bool isOnline);
}
