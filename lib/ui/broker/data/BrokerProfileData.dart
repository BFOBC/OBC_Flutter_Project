import 'package:flutter/material.dart';

class BrokerProfileData {
  String id; // Firebase Auth UID
  String name;
  String website;
  String country;
  List<String> license;
  String email;
  String paymentTerms;
  String? profilePictureUrl; // New field for profile picture URL

  BrokerProfileData({
    required this.id,
    required this.name,
    required this.website,
    required this.country,
    required this.license,
    required this.email,
    required this.paymentTerms,
    this.profilePictureUrl,
  });

  // Convert object to Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'website': website,
      'country': country,
      'license': license,
      'email': email,
      'paymentTerms': paymentTerms,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  // Create object from Firestore document snapshot
  factory BrokerProfileData.fromMap(String id, Map<String, dynamic> map) {
    return BrokerProfileData(
      id: id,
      name: map['name'] ?? '',
      website: map['website'] ?? '',
      country: map['country'] ?? '',
      license: List<String>.from(map['license'] ?? []),
      email: map['email'] ?? '',
      paymentTerms: map['paymentTerms'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
    );
  }
}

class BrokerProfileProvider with ChangeNotifier {
  BrokerProfileData _profile = BrokerProfileData(
    id: 'OBC001',
    name: '',
    website: '',
    country: '',
    license: ['', '', ''],
    email: "",
    paymentTerms: "",
    profilePictureUrl: null, // Initialize new field
  );

  BrokerProfileData get profile => _profile;

  void updateProfile(BrokerProfileData updatedProfile) {
    _profile = updatedProfile;
    notifyListeners();
  }

  void updateField(String field, dynamic value) {
    switch (field) {
      case 'name':
        _profile.name = value as String;
        break;
      case 'website':
        _profile.website = value as String;
        break;
      case 'country':
        _profile.country = value as String;
        break;
      case 'license':
        _profile.license = List<String>.from(value as List<dynamic>);
        break;
      case 'email':
        _profile.email = value as String;
        break;
      case 'paymentTerms':
        _profile.paymentTerms = value as String;
        break;
      case 'profilePictureUrl':
        _profile.profilePictureUrl = value as String?;
        break;
    }
    notifyListeners();
  }
}
