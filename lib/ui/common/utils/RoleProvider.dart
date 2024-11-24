import 'package:flutter/foundation.dart';
import '../../broker/data/BrokerProfileData.dart';

enum UserRole {
  broker,
  courier,
}

class RoleProvider with ChangeNotifier {
  UserRole _role = UserRole.broker; // Default role can be set here
  BrokerProfileData _profile = BrokerProfileData(
    id: 'OBC001',
    name: 'John Doe',
    website: 'www.johndoe.com',
    country: 'USA',
    license: ['XYZ-1234', 'ABC-5678', 'DEF-9012'],
    email: "broker@gmail.com",
    paymentTerms: "hehe",
  );

  // Role-related logic
  UserRole get role => _role;

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  // Profile-related logic
  BrokerProfileData get profile => _profile;

  void updateProfile(BrokerProfileData updatedProfile) {
    _profile = updatedProfile;
    notifyListeners();
  }
}
