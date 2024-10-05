import 'dart:ffi';

class BrokerProfileData {
  final String brokerID; // read only
  final String name; // read only
  final String website; // add by broker
  final String country;
  final String password;
  final String phoneNumber;
  final String profilePicture;
  final List<String> license;
  final String email; // read only
  final String paymentTerms;
  final Double jobCompleted; // Number of job completed first get from DB then increment
  final Bool isAllowedToOperate; // admin will allow
  final Bool isOnline; // can change from nav drawer true - false
  BrokerProfileData({
    required this.brokerID,
    required this.name,
    required this.website,
    required this.country,
    required this.license,
    required this.email,
    required this.paymentTerms,
    required this.jobCompleted,
    required this.isAllowedToOperate,
    required this.profilePicture,
    required this.password,
    required this.phoneNumber,
    required this.isOnline
  });
}
