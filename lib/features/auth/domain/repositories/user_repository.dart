import '../entities/user.dart';
import '../../../../core/errors/failures.dart';

abstract class UserRepository {
  Future<({Failure? failure, User? data})> createUser(String username);
  Future<({Failure? failure, User? data})> getCurrentUser();
  Future<({Failure? failure, List<User>? data})> getAllUsers();
  Future<({Failure? failure, User? data})> getUserById(String id);
  Future<({Failure? failure, List<User>? data})> searchUsers(String query);
  Future<({Failure? failure, bool? data})> updateUser(User user);
  Future<({Failure? failure, bool? data})> deleteUser(String id);
  Future<({Failure? failure, bool? data})> updateOnlineStatus(String userId, bool isOnline);
}
