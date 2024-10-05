import 'dart:ffi';

class JobDetails {
  final String jobID;
  final String courierID;
  final String brokerID;
  final String fromLocation; // three letter airport code
  final String toLocation; // three letter airport code
  final String startDateTime;
  final String endDateTime;
  final String courierCapacity; // parcel weight and unit
  final String acceptanceStatus; // acceptance status pending - reject - accept
  final String jobType; // Submission - EmptyLeg
  final String bid; // amount
  final Double jobNumber; // increment every time first get no from DB then increment
  final String jobStatus; // todo - inprogress - done
  JobDetails({
    required this.jobID,
    required this.courierID,
    required this.brokerID,
    required this.fromLocation,
    required this.toLocation,
    required this.startDateTime,
    required this.endDateTime,
    required this.courierCapacity,
    required this.acceptanceStatus,
    required this.jobType,
    required this.bid,
    required this.jobNumber,
    required this.jobStatus
  });
}
