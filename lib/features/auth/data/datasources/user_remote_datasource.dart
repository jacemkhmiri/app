import '../../domain/entities/user.dart';

abstract class UserRemoteDataSource {
  Future<User> createUser(String username);
  Future<User> getCurrentUser();
  Future<List<User>> getAllUsers();
  Future<User> getUserById(String id);
  Future<List<User>> searchUsers(String query);
  Future<User> updateUser(User user);
  Future<void> deleteUser(String id);
  Future<void> updateOnlineStatus(String userId, bool isOnline);
}
