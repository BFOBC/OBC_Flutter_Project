import 'package:flutter/material.dart';

import '../../common/models/Rating.dart';

/*class Rating {
  String from; // The user who gave the rating (courier ID)
  double rating;
  String comment;

  Rating({
    required this.from,
    required this.rating,
    required this.comment,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'rating': rating,
      'comment': comment,
    };
  }

  // Create from Firestore map
  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      from: map['from'] ?? '',
      rating: (map['rating'] is int) ? (map['rating'] as int).toDouble() : (map['rating'] ?? 0.0),
      comment: map['comment'] ?? '',
    );
  }
}*/

class BrokerProfileData {
  String brokerID;
  String name;
  String contact;
  double rating;
  String website;
  String company;
  String country;
  List<String> license;
  String email;
  String paymentTerms;
  String? profilePictureUrl;
  List<Rating> ratings; // New field for storing ratings

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
    this.ratings = const [],
  });

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
      'ratings': ratings.map((r) => r.toMap()).toList(), // Convert ratings to a list of maps
    };
  }

  factory BrokerProfileData.fromMap(String id, Map<String, dynamic> map) {
    return BrokerProfileData(
      brokerID: id,
      name: map['name'] ?? 'Unknown',
      contact: map['contact'] ?? 'N/A',
      rating: (map['rating'] is int) ? (map['rating'] as int).toDouble() : (map['rating'] ?? 0.0),
      website: map['website'] ?? 'N/A',
      company: map['company'] ?? 'N/A',
      country: map['country'] ?? 'N/A',
      license: map['license'] != null ? List<String>.from(map['license']) : [],
      email: map['email'] ?? 'N/A',
      paymentTerms: map['paymentTerms'] ?? 'N/A',
      profilePictureUrl: map['profilePictureUrl'] as String?,
      ratings: map['ratings'] != null
          ? List<Rating>.from(map['ratings'].map((r) => Rating.fromMap(r)))
          : [],
    );
  }
}
