class Passport {
  String countryName;
  String passportNumber;
  String issueDate;
  String expiryDate;

  Passport({
    required this.countryName,
    required this.passportNumber,
    required this.issueDate,
    required this.expiryDate,
  });

  // Convert Passport object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'countryName': countryName,
      'passportNumber': passportNumber,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
    };
  }

  // Create Passport object from Firestore Map
  factory Passport.fromMap(Map<String, dynamic> map) {
    return Passport(
      countryName: map['countryName'] ?? 'N/A',  // Use 'N/A' if null
      passportNumber: map['passportNumber'] ?? 'N/A',  // Use 'N/A' if null
      issueDate: map['issueDate'] ?? 'N/A',   // Use 'N/A' if null
      expiryDate: map['expiryDate'] ?? 'N/A', // Use 'N/A' if null
    );
  }
}
