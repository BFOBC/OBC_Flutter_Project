import 'package:flutter/material.dart';

class BrokerProfileData {
  String id;
  String name;
  String website;
  String country;
  List<String> license;
  String email;
  String paymentTerms;
  String? docId;

  BrokerProfileData({
    required this.id,
    required this.name,
    required this.website,
    required this.country,
    required this.license,
    required this.email,
    required this.paymentTerms,
    this.docId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'website': website,
      'country': country,
      'license': license,
      'email': email,
      'paymentTerms': paymentTerms,
      'docId': docId,
    };
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
  );

  BrokerProfileData get profile => _profile;

  void updateProfile(BrokerProfileData updatedProfile) {
    _profile = updatedProfile;
    notifyListeners();
  }
}
