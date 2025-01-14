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
  });
}
