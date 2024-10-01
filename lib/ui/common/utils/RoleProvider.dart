// role_provider.dart
import 'package:flutter/foundation.dart';

enum UserRole {
  broker,
  courier,
}

class RoleProvider with ChangeNotifier {
  UserRole _role = UserRole.broker; // Default role can be set here

  UserRole get role => _role;

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }
}
