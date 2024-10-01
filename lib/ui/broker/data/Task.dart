class Task {
  final String brokerId;
  final String flightNumber;
  final String departureFrom;
  final String arriveAt;
  final String status; // Differentiates between In Progress, Completed, and Todo
  final double rating; // Differentiates between In Progress, Completed, and Todo
  final String startDateTime; // Differentiates between In Progress, Completed, and Todo
  final String endDateTime; // Differentiates between In Progress, Completed, and Todo
  final String bid; // Differentiates between In Progress, Completed, and Todo

  Task({
    required this.brokerId,
    required this.flightNumber,
    required this.departureFrom,
    required this.arriveAt,
    required this.status,
    required this.rating,
    required this.startDateTime,
    required this.endDateTime,
    required this.bid,
  });
}
