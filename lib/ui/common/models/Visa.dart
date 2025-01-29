class Visa {
  final String countryName;
  final String expiryDate;

  Visa({
    required this.countryName,
    required this.expiryDate,
  });

  // Optional: Method to convert a Visa object to a Map
  Map<String, dynamic> toMap() {
    return {
      'countryName': countryName,
      'expiryDate': expiryDate,
    };
  }

  // Optional: Factory method to create a Visa object from a Map
  factory Visa.fromMap(Map<String, dynamic> map) {
    return Visa(
      countryName: map['countryName'] ?? 'N/A',  // Use 'N/A' if null
      expiryDate: map['expiryDate'] ?? 'N/A',    // Use 'N/A' if null
    );
  }
}
