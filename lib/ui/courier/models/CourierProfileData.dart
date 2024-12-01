import '../../common/models/Passport.dart';
import '../../common/models/Visa.dart';

class CourierProfileData {
  String? id; // Nullable
  late final String? name; // Nullable
  final String? website; // Nullable
  final String? country; // Nullable
  final List<String>? license; // Nullable
  String? email; // Nullable
  final String? paymentTerms; // Nullable
  final List<Visa> visas;
  final List<Passport> passports;

  var profilePictureUrl;

  CourierProfileData({
    this.id,
    this.name,
    this.website,
    this.country,
    this.license,
    this.email,
    this.paymentTerms,
    required this.visas,
    required this.passports, required String courierID,
  });

  // Method to convert to Map and ignore null values
  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{};

    if (id != null) data['id'] = id;
    if (name != null) data['name'] = name;
    if (website != null) data['website'] = website;
    if (country != null) data['country'] = country;
    if (license != null) data['license'] = license;
    if (email != null) data['email'] = email;
    if (paymentTerms != null) data['paymentTerms'] = paymentTerms;

    return data;
  }

  // Factory method to create an instance from a Map
  factory CourierProfileData.fromMap(Map<String, dynamic> map) {
    return CourierProfileData(
      id: map['id'] as String?,
      name: map['name'] as String?,
      website: map['website'] as String?,
      country: map['country'] as String?,
      license: (map['license'] as List<dynamic>?)?.map((e) => e as String).toList(),
      email: map['email'] as String?,
      paymentTerms: map['paymentTerms'] as String?,
      visas: (map['visa'] as List<dynamic>?)!.map((e) => e as Visa).toList(),
      passports: (map['passport'] as List<dynamic>?)!.map((e) => e as Passport).toList(), courierID: '');
  }

  String? get courierID => id;
}
