import 'dart:ffi';

import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';

class Task {
  String? brokerId;
  String? flightNumber;
  String? departureFrom;
  String? arriveAt;
  String? status;
  double? rating;
  String? startDateTime;
  String? endDateTime;
  String? milestoneStartDateTime;
  String? milestoneEndDateTime;
  String? mileStoneStatus;
  String? emptyLegRequestID;
  String? bid;
  String? description;
  String? title;
  String? isCourierRated;
  String? isBrokerRated;
  String? courierCapacity;
  Task({
    this.brokerId,
    this.flightNumber,
    this.departureFrom,
    this.arriveAt,
    this.status,
    this.rating,
    this.startDateTime,
    this.endDateTime,
    this.milestoneStartDateTime,
    this.milestoneEndDateTime,
    this.mileStoneStatus,
    this.emptyLegRequestID,
    this.bid,
    this.title,
    this.description,
    this.isCourierRated,
    this.isBrokerRated,
    this.courierCapacity
  });
  // Getters for local time conversion
  String get localStartDateTime => convertUTCToLocal(startDateTime ?? '');
  String get localEndDateTime => convertUTCToLocal(endDateTime ?? '');
}
