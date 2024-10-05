class CourierProfileData {
  final String id;
  final String name;
  final String website;
  final String country;
  final List<String> license;  // Make sure license is a List<String>
  final String email;
  final String paymentTerms;
  CourierProfileData({
    required this.id,
    required this.name,
    required this.website,
    required this.country,
    required this.license,
    required this.email,
    required this.paymentTerms,// This should now be a list of strings
  });
}
