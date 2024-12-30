import 'package:broker_flutter_pp/ui/broker/data/BrokerProfileData.dart';
import 'package:broker_flutter_pp/ui/common/models/Passport.dart';
import 'package:broker_flutter_pp/ui/common/models/Visa.dart';
import 'package:broker_flutter_pp/ui/courier/models/CourierProfileData.dart';
import 'package:flutter/foundation.dart';

enum UserRole {
  broker,
  courier,
}

class RoleProvider with ChangeNotifier {
  UserRole _role = UserRole.broker; // Default role can be set here
  BrokerProfileData _brokerProfileData = BrokerProfileData(
    id: 'OBC001',
    name: 'John Doe',
    website: 'www.johndoe.com',
    country: 'USA',
    license: ['XYZ-1234', 'ABC-5678', 'DEF-9012'],
    email: "broker@gmail.com",
    paymentTerms: "hehe",
  );
  CourierProfileData courierProfileData = CourierProfileData(
  id: "C12345",
  name: "John Doe",
  website: "www.johndoe.com",
  country: "USA",
  license: ["Driving License A123", "Commercial License B456"],
  email: "john.doe@example.com",
  paymentTerms: "Net 30",
  visas: [
      Visa(
        countryName: "USA",
        expiryDate: DateTime.parse("2025-12-31").toString(),
      ),
      Visa(
        countryName: "USA",
        expiryDate: DateTime.parse("2025-12-31").toString(),
      ),
    ],
    passports: [
      Passport(
        countryName: "John Doe",
        passportNumber: "test222",
        issueDate: DateTime.parse("2026-05-01").toString(),

        expiryDate: DateTime.parse("2026-05-01").toString(),
      ),
    ], courierID: '',
    phoneNumber: '',
    address: '',
    occupation: ''
  );

  // Role-related logic
  UserRole get role => _role;

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  // Profile-related logic
  BrokerProfileData get brokerProfile => _brokerProfileData;

  CourierProfileData get courierProfile => courierProfileData;

  void updateProfile(BrokerProfileData updatedProfile) {
    _brokerProfileData = updatedProfile;
    notifyListeners();
  }
}
