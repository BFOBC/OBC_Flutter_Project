import 'package:broker_flutter_pp/ui/broker/model/BrokerProfileData.dart';
import 'package:broker_flutter_pp/ui/common/models/Passport.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
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
    brokerID: 'OBC001',
    name: 'John Doe',
    contact: 'XYZ',
    rating: 0,
    website: 'www.johndoe.com',
    company: 'OBC',
    country: 'USA',
    phoneNumber: '+923065000660',
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
  /// 🔴 Your dynamic milestone node ID list
  late List<String> _listMilestoneNodeIDS = [];
  /// ✅ Getter
  List<String> get listMilestoneNodeIDS => _listMilestoneNodeIDS;
  /// ✅ Setter / Save method
  void setMilestoneNodeIDS(List<String> newList) {
    _listMilestoneNodeIDS = newList;
    notifyListeners(); // Optional: Only if UI depends on this
  }
  /// ✅ Add single item
  void addMilestoneNodeID(String id) {
    if (!_listMilestoneNodeIDS.contains(id)) {
      _listMilestoneNodeIDS.add(id);
      notifyListeners();
    }
  }
  /// ✅ Remove single item
  void removeMilestoneNodeID(String id) {
    _listMilestoneNodeIDS.remove(id);
    notifyListeners();
  }
  /// ✅ Clear all
  void clearMilestoneNodeIDS() {
    _listMilestoneNodeIDS.clear();
    notifyListeners();
  }

  /// 🔵 Single task instance
  Task? _task;

  /// ✅ Getter
  Task? get task => _task;

  /// ✅ Setter / Save method
  void setTask(Task newTask) {
    _task = newTask;
    notifyListeners(); // Notify UI if it's listening
  }

  /// ✅ Clear / Delete method
  void clearTask() {
    _task = null;
    notifyListeners();
  }

  /// ✅ Check if task is available
  bool get hasTask => _task != null;
}
