class User {
  final int id;
  String name;
  String email;
  String phone;
  String address;
  String airport;
  String role;
  bool isActive;
  bool isDeleted;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.airport,
    required this.role,
    this.isActive = true,
    this.isDeleted = false,
  });
}
