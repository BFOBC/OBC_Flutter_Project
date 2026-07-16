import '../../common/models/Rating.dart';

class BrokerProfileData {
  final String brokerID;
  final String name;
  final String contact;
  final double rating;
  final String website;
  final String company;
  final String country;
  final String phoneNumber;
  final List<String> license;
  final String email;
  final String paymentTerms;
  final String? profilePictureUrl;
  final List<Rating> ratings;

  BrokerProfileData({
    required this.brokerID,
    required this.name,
    required this.contact,
    required this.rating,
    required this.website,
    required this.company,
    required this.country,
    required this.phoneNumber,
    required this.license,
    required this.email,
    required this.paymentTerms,
    this.profilePictureUrl,
    this.ratings = const [],
  });

  factory BrokerProfileData.fromMap(String id, Map<String, dynamic> map) {
    return BrokerProfileData(
      brokerID: id,
      name: map['name']?.toString() ?? 'Unknown',
      contact: map['contact']?.toString() ?? 'N/A',
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      website: map['website']?.toString() ?? 'N/A',
      company: map['company']?.toString() ?? 'N/A',
      country: map['country']?.toString() ?? 'N/A',
      phoneNumber: map['phoneNumber']?.toString() ?? 'N/A',
      license: (map['license'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      email: map['email']?.toString() ?? 'N/A',
      paymentTerms: map['paymentTerms']?.toString() ?? 'N/A',
      profilePictureUrl: map['profilePictureUrl'] as String?,
      ratings: (map['ratings'] as List<dynamic>?)
          ?.map((r) => Rating.fromMap(r as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brokerID': brokerID,
      'name': name,
      'contact': contact,
      'rating': rating,
      'website': website,
      'company': company,
      'country': country,
      'phoneNumber': phoneNumber,
      'license': license,
      'email': email,
      'paymentTerms': paymentTerms,
      'profilePictureUrl': profilePictureUrl,
      'ratings': ratings.map((r) => r.toMap()).toList(),
    };
  }
}
