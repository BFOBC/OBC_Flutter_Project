import 'package:broker_flutter_pp/ui/common/models/Rating.dart';

import '../../common/models/Passport.dart';
import '../../common/models/Visa.dart';

class CourierProfileData {
  String? id; // Nullable
  late final String? name; // Nullable
  String? website; // Nullable
  String? country; // Nullable
  List<String>? license; // Nullable
  String? email; // Nullable
  String? paymentTerms; // Nullable
  List<Visa> visas; // List of Visa objects
  List<Passport> passports; // List of Passport objects
  String? phoneNumber;
  String? address;
  bool? hasCar;
  bool? hasDrivingLicence;
  bool? willingToDoFirstLastMile;
  String? countryCode;

  String? profilePictureUrl; // Define it as a nullable String for URL
  final List<Rating> ratings;
  // Empty constructor
  CourierProfileData({
    this.id,
    this.name,
    this.website,
    this.country,
    this.license,
    this.email,
    this.paymentTerms,
    List<Visa>? visas,
    List<Passport>? passports,
    String? courierID,
    this.phoneNumber,
    this.address,
    this.hasCar,
    this.hasDrivingLicence,
    this.willingToDoFirstLastMile,
    this.profilePictureUrl, // Added profilePictureUrl to the constructor
    this.countryCode, // Added profilePictureUrl to the constructor
    this.ratings = const [],
  })  : visas = visas ?? [], // Default to an empty list if null
        passports = passports ?? [], // Default to an empty list if null
        _courierID = courierID ?? ''; // Default to an empty string if null

  // Private variable for courierID to ensure it's not directly set
  late String _courierID;

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
    if (profilePictureUrl != null) data['profilePictureUrl'] = profilePictureUrl; // Added field to Map
    if (countryCode != null) data['countryCode'] = countryCode; // Added field to Map

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
      visas: (map['visas'] as List<dynamic>?)
          ?.map((e) => Visa.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      passports: (map['passports'] as List<dynamic>?)
          ?.map((e) => Passport.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      courierID: map['courierID'] as String? ?? '', // Use the key if it exists
      phoneNumber: map['phoneNumber'] as String?,
      address: map['address'] as String?,
      hasCar: map['car'] as bool?,
      hasDrivingLicence: map['drivingLicence'] as bool?,
      willingToDoFirstLastMile: map['firstLastMile'] as bool?,
      profilePictureUrl: map['profilePictureUrl'] as String?, // Added field
      countryCode: map['countryCode'] as String?, // Added field
      ratings: (map['ratings'] as List<dynamic>?)
          ?.map((r) => Rating.fromMap(r as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // Getter for courierID
  String get courierID => _courierID;
}
