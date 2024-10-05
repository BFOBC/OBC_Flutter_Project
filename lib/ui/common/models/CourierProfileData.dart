import 'dart:ffi';
import 'Passport.dart';
import 'Visa.dart';

class CourierProfileData {
  final String courierID; // read only
  final String name; // read only
  final String password;
  final String email; // read only
  final String profilePicture;
  final String phoneNumber;
  final Double jobCompleted; // Number of jobs completed first get from DB then increment
  final Double currentLocation; // get from map or GPS
  final Double baseLocation; // can add or change by courier from airport list on map
  final Bool isOnline; // can change by courier nav drawer
  final Bool availabilityStatus; // true - false
  final Bool isAllowedToOperate; // admin will allow
  final Bool haveDrivingLicense;
  final Bool willingToFirstLastMile;
  final Bool haveCar;
  final List<Visa> visa;
  final List<Passport> passport;

  CourierProfileData({
    required this.courierID,
    required this.name,
    required this.password,
    required this.visa,
    required this.passport,
    required this.email,
    required this.haveDrivingLicense,
    required this.willingToFirstLastMile,
    required this.haveCar,
    required this.jobCompleted,
    required this.currentLocation,
    required this.baseLocation,
    required this.isOnline,
    required this.availabilityStatus,
    required this.isAllowedToOperate,
    required this.profilePicture,
    required this.phoneNumber
  });
}
