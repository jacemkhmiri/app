import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  final List<User> _allUsers = [];
  final List<User> _discoveredUsers = [];

  User? get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;
  List<User> get discoveredUsers => _discoveredUsers;

  void setUser(User? user) {
    _currentUser = user;
    if (user != null && !_allUsers.any((u) => u.id == user.id)) {
      _allUsers.add(user);
    }
    notifyListeners();
  }

  void createUser(String username) {
    final newUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: username,
      isOnline: true,
    );
    _allUsers.add(newUser);

    // Add sample users for testing
    if (_allUsers.length == 1) {
      _addSampleUsers();
    }

    notifyListeners();
  }

  void discoverUser(User user) {
    if (!_discoveredUsers.any((u) => u.id == user.id)) {
      _discoveredUsers.add(user);
      notifyListeners();
    }
  }

  User? findUserByUsername(String username) {
    try {
      return _allUsers.firstWhere((user) => user.name == username);
    } catch (e) {
      return null;
    }
  }

  List<User> searchUsers(String query) {
    if (query.isEmpty) return [];
    return _allUsers
        .where((user) =>
            user.name.toLowerCase().contains(query.toLowerCase()) &&
            user.id != _currentUser?.id)
        .toList();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void _addSampleUsers() {
    final sampleUsers = [
      User(id: 'user_alice', name: 'Alice', isOnline: true),
      User(id: 'user_bob', name: 'Bob', isOnline: false),
      User(id: 'user_charlie', name: 'Charlie', isOnline: true),
      User(id: 'user_diana', name: 'Diana', isOnline: true),
      User(id: 'user_eve', name: 'Eve', isOnline: false),
    ];
    _allUsers.addAll(sampleUsers);
  }
}