import 'package:flutter/material.dart';

import 'User.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [
    User(id: 1, name: "Alice", email: "alice@air.com", phone: "1234567890", address: "Terminal 1", airport: "JFK", role: "Courier"),
    User(id: 2, name: "Bob", email: "bob@broker.com", phone: "1112223333", address: "H Block", airport: "LAX", role: "Broker"),
    User(id: 3, name: "Carol", email: "carol@mod.com", phone: "9998887777", address: "Central", airport: "ORD", role: "Modulator", isActive: false),
    User(id: 4, name: "Dave", email: "dave@admin.com", phone: "4445556666", address: "Apt 4", airport: "ATL", role: "Admin"),
    User(id: 5, name: "Eve", email: "eve@super.com", phone: "5556667777", address: "Street 9", airport: "DXB", role: "SuperAdmin"),
  ];

  String currentUserRole = "Admin"; // Simulated user role

  List<User> get activeUsers => _users.where((u) => !u.isDeleted).toList();
  List<User> get deletedUsers => _users.where((u) => u.isDeleted).toList();

  void addUser(User user) {
    _users.add(user);
    notifyListeners();
  }

  void updateUser(User updatedUser) {
    int index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
      notifyListeners();
    }
  }

  void deleteUser(int id) {
    int index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      _users[index].isDeleted = true;
      notifyListeners();
    }
  }

  void restoreUser(int id) {
    int index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      _users[index].isDeleted = false;
      notifyListeners();
    }
  }

  void toggleUserStatus(int id) {
    int index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      _users[index].isActive = !_users[index].isActive;
      notifyListeners();
    }
  }
}
