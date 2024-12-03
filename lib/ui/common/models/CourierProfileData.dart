import 'package:broker_flutter_pp/ui/common/models/Passport.dart';
import 'package:broker_flutter_pp/ui/common/models/Visa.dart';

class CourierProfileData {
  String courierID;
  String name;
  String email;
  String _profilePictureUrl; // Private field for profilePictureUrl
  List<Visa> visas;
  List<Passport> passports;

  CourierProfileData({
    required this.courierID,
    required this.name,
    required this.email,
    required this.visas,
    required this.passports,
    String profilePictureUrl = "",  // Default value
  }) : _profilePictureUrl = profilePictureUrl;

  // Getter for profilePictureUrl
  String get profilePictureUrl => _profilePictureUrl;

  // Setter for profilePictureUrl
  set profilePictureUrl(String url) {
    _profilePictureUrl = url;
  }

  factory CourierProfileData.fromMap(Map<String, dynamic> map) {
    return CourierProfileData(
      courierID: map['courierID'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',  // From map
      visas: (map['visas'] as List<dynamic>? ?? [])
          .map((e) => Visa.fromMap(e as Map<String, dynamic>))
          .toList(),
      passports: (map['passports'] as List<dynamic>? ?? [])
          .map((e) => Passport.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courierID': courierID,
      'name': name,
      'email': email,
      'profilePictureUrl': _profilePictureUrl,  // Use private field
      'visas': visas.map((e) => e.toMap()).toList(),
      'passports': passports.map((e) => e.toMap()).toList(),
    };
  }
}

class Passport {
  final String id;
  final String country;

  Passport({required this.id, required this.country});

  factory Passport.fromMap(Map<String, dynamic> map) {
    return Passport(
      id: map['id'] ?? '',
      country: map['country'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'country': country,
    };
  }
}

class Visa {
  final String expiryDate;
  final String countryName;

  Visa({required this.expiryDate, required this.countryName});

  factory Visa.fromMap(Map<String, dynamic> map) {
    return Visa(
      expiryDate: map['expiry date'] ?? '',
      countryName: map['country'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': expiryDate,
      'country': countryName,
    };
  }
}

