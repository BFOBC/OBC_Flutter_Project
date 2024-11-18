class CourierProfile {
  String courierID;
  String name;
  String email;
  String profilePicture;
  String phoneNumber;
  int jobCompleted;
  String currentLocation;
  String baseLocation;
  bool isOnline;
  String availabilityStatus;
  bool isAllowedToOperate;
  bool haveDrivingLicense;
  bool willingToFirstLastMile;
  bool haveCar;
  List<Visa> visas;
  List<Passport> passports;

  CourierProfile({
    required this.courierID,
    required this.name,
    required this.email,
    this.profilePicture = "",
    this.phoneNumber = "",
    this.jobCompleted = 0,
    this.currentLocation = "",
    this.baseLocation = "",
    this.isOnline = false,
    this.availabilityStatus = "",
    this.isAllowedToOperate = false,
    this.haveDrivingLicense = false,
    this.willingToFirstLastMile = false,
    this.haveCar = false,
    this.visas = const [],
    this.passports = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'courierID': courierID,
      'name': name,
      'email': email,
      'profilePicture': profilePicture.isEmpty ? "" : profilePicture,
      'phoneNumber': phoneNumber.isEmpty ? "" : phoneNumber,
      'jobCompleted': jobCompleted,
      'currentLocation': currentLocation.isEmpty ? "" : currentLocation,
      'baseLocation': baseLocation.isEmpty ? "" : baseLocation,
      'isOnline': isOnline,
      'availabilityStatus': availabilityStatus.isEmpty ? "" : availabilityStatus,
      'isAllowedToOperate': isAllowedToOperate,
      'haveDrivingLicense': haveDrivingLicense,
      'willingToFirstLastMile': willingToFirstLastMile,
      'haveCar': haveCar,
      'visas': visas.isNotEmpty ? visas.map((visa) => visa.toMap()).toList() : [],
      'passports': passports.isNotEmpty ? passports.map((passport) => passport.toMap()).toList() : [],
    };
  }
}

class Visa {
  String countryName;
  DateTime? expiryDate;

  Visa({required this.countryName, this.expiryDate});

  Map<String, dynamic> toMap() {
    return {
      'countryName': countryName.isEmpty ? "" : countryName,
      'expiryDate': expiryDate != null ? expiryDate!.toIso8601String() : "",
    };
  }
}

class Passport {
  String countryName;
  DateTime? expiryDate;

  Passport({required this.countryName, this.expiryDate});

  Map<String, dynamic> toMap() {
    return {
      'countryName': countryName.isEmpty ? "" : countryName,
      'expiryDate': expiryDate != null ? expiryDate!.toIso8601String() : "",
    };
  }
}
