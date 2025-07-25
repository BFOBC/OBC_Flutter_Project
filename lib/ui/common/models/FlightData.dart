class FlightData {
  final DateTime fromDateTime; // Change to DateTime
  final DateTime toDateTime; // Change to DateTime
  final String fromLocation;
  final String toLocation;
  final String flightNumber;
  final String emptyLegTBLNodeID;
  final int capacity;

  FlightData({
    required this.fromDateTime,
    required this.toDateTime,
    required this.fromLocation,
    required this.toLocation,
    required this.flightNumber,
    required this.emptyLegTBLNodeID,
    required this.capacity,
  });
}