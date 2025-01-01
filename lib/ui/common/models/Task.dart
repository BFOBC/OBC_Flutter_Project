class Task {
  String? brokerId;
  String? flightNumber;
  String? departureFrom;
  String? arriveAt;
  String? status; // Differentiates between In Progress, Completed, and Todo
  double? rating; // Differentiates between In Progress, Completed, and Todo
  String? startDateTime; // Differentiates between In Progress, Completed, and Todo
  String? endDateTime; // Differentiates between In Progress, Completed, and Todo
  String? bid; // Differentiates between In Progress, Completed, and Todo

  Task({
    this.brokerId,
    this.flightNumber,
    this.departureFrom,
    this.arriveAt,
    this.status,
    this.rating,
    this.startDateTime,
    this.endDateTime,
    this.bid,
  });
}
