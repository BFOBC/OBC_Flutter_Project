class Passport {
  final String countryName;
  final String expiryDate;

  Passport({
    required this.countryName,
    required this.expiryDate,
  });

  // Optional: Method to convert a Passport object to a Map
  Map<String, dynamic> toMap() {
    return {
      'countryName': countryName,
      'expiryDate': expiryDate,
    };
  }

  // Optional: Factory method to create a Passport object from a Map
  factory Passport.fromMap(Map<String, dynamic> map) {
    return Passport(
      countryName: map['countryName'],
      expiryDate: map['expiryDate'],
    );
  }
}
