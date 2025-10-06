import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../datasources/user_local_datasource.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<({Failure? failure, User? data})> createUser(String username) async {
    try {
      // Create user locally first
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: username,
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      // Save to local storage
      await localDataSource.saveUser(user);

      return (failure: null, data: user);
    } on CacheException catch (e) {
      return (failure: CacheFailure(message: e.message), data: null);
    } catch (e) {
      return (failure: ServerFailure(message: e.toString()), data: null);
    }
  }

  @override
  Future<({Failure? failure, User? data})> getCurrentUser() async {
    try {
      final user = await localDataSource.getCurrentUser();
      return (failure: null, data: user);
    } on CacheException catch (e) {
      return (failure: CacheFailure(message: e.message), data: null);
    } catch (e) {
      return (failure: ServerFailure(message: e.toString()), data: null);
    }
  }

  @override
  Future<({Failure? failure, List<User>? data})> getAllUsers() async {
    try {
      final users = await localDataSource.getAllUsers();
      return (failure: null, data: users);
    } on CacheException catch (e) {
      return (failure: CacheFailure(message: e.message), data: null);
    } catch (e) {
      return (failure: ServerFailure(message: e.toString()), data: null);
    }
  }

  @override
  Future<({Failure? failure, User? data})> getUserById(String id) async {
    try {
      final user = await localDataSource.getUserById(id);
      return (failure: null, data: user);
    } on CacheException catch (e) {
      return (failure: CacheFailure(message: e.message), data: null);
    } catch (e) {
      return (failure: ServerFailure(message: e.toString()), data: null);
    }
  }

  @override
  Future<({Failure? failure, List<User>? data})> searchUsers(String query) async {
    try {
      final users = await localDataSource.searchUsers(query);
      return (failure: null, data: users);
    } on CacheException catch (e) {
      return (failure: CacheFailure(message: e.message), data: null);
    } catch (e) {
      return (failure: ServerFailure(message: e.toString()), data: null);
    }
  }

  @override
  Future<({Failure? failure, bool? data})> updateUser(User user) async {
    try {
      await localDataSource.updateUser(user);
      return (failure: null, data: true);
    } on CacheException catch (e) {
      return (failure: CacheFailure(message: e.message), data: null);
    } catch (e) {
      return (failure: ServerFailure(message: e.toString()), data: null);
    }
  }

  @override
  Future<({Failure? failure, bool? data})> deleteUser(String id) async {
    try {
      await localDataSource.deleteUser(id);
      return (failure: null, data: true);
    } on CacheException catch (e) {
      return (failure: CacheFailure(message: e.message), data: null);
    } catch (e) {
      return (failure: ServerFailure(message: e.toString()), data: null);
    }
  }

  @override
  Future<({Failure? failure, bool? data})> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await localDataSource.updateOnlineStatus(userId, isOnline);
      return (failure: null, data: true);
    } on CacheException catch (e) {
      return (failure: CacheFailure(message: e.message), data: null);
    } catch (e) {
      return (failure: ServerFailure(message: e.toString()), data: null);
    }
  }
}
