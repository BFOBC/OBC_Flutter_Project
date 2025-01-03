import 'dart:ffi';

import 'package:flutter/material.dart';

class BrokerProfileData {
  String brokerID; // Firebase Auth UID
  String name;
  String contact;
  double rating;
  String website;
  String company;
  String country;
  List<String> license;
  String email;
  String paymentTerms;
  String? profilePictureUrl; // New field for profile picture URL

  BrokerProfileData({
    required this.brokerID,
    required this.name,
    required this.contact,
    required this.rating,
    required this.website,
    required this.company,
    required this.country,
    required this.license,
    required this.email,
    required this.paymentTerms,
    this.profilePictureUrl,
  });

  // Convert object to Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'brokerID': brokerID,
      'name': name,
      'contact': contact,
      'rating': rating,
      'website': website,
      'company': company,
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
      brokerID: map['brokerID'] ?? '',
      name: map['name'] ?? 'N/A',
      contact: map['contact'] ??  'N/A',
      rating: _parseRating(map['rating']),
      // Updated to handle type conversion
      website: map['website'] ??  'N/A',
      company: map['company'] ??  'N/A',
      country: map['country'] ??  'N/A',
      license: List<String>.from(map['license'] ?? []),
      email: map['email'] ?? '',
      paymentTerms: map['paymentTerms'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] != null
          ? map['profilePictureUrl'] as String?
          : null, // Safely handle null
    );
  }
  // Helper method to safely parse the rating field
  static double _parseRating(dynamic rating) {
    if (rating is double) {
      return rating;
    } else if (rating is String) {
      // Try to parse string as double
      return double.tryParse(rating) ?? 0.0; // Default to 0.0 if parsing fails
    }
    return 0.0; // Default to 0.0 if rating is not provided or invalid
  }
}

class BrokerProfileProvider with ChangeNotifier {
  BrokerProfileData _profile = BrokerProfileData(
    brokerID: 'OBC001',
    name: 'N/A',
    contact:  'N/A',
    rating:0,
    website:  'N/A',
    company:  'N/A',
    country:  'N/A',
    license: ['', '', ''],
    email:  'N/A',
    paymentTerms:  'N/A',
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
      case 'contact':
        _profile.contact = value as String;
      case 'rating':
        _profile.rating = value as double;
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
        _profile.profilePictureUrl = value as String?; // Allow null values here
        break;
    }
    notifyListeners();
  }

}
