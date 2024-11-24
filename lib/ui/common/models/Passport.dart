class Passport {
  final String countryName;
  final String passportNumber;
  final String issueDate;
  final String expiryDate;

  Passport({
    required this.countryName,
    required this.passportNumber,
    required this.issueDate,
    required this.expiryDate,
  });

  // Define the toMap() method
  Map<String, dynamic> toMap() {
    return {
      'countryName': countryName,
      'passportNumber': passportNumber,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
    };
  }
}
