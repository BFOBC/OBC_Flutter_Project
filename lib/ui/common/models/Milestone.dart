class Milestone {
  final String title;
  final String description;
  final String startTimeAndDate;
  final String endTimeAndDate;
  final String courierID;
  final String brokerID;
  String? nodeID;

  Milestone({
    required this.title,
    required this.description,
    required this.startTimeAndDate,
    required this.endTimeAndDate,
    required this.courierID,
    required this.brokerID,
    required this.nodeID,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startTimeAndDate': startTimeAndDate,
      'endTimeAndDate': endTimeAndDate,
      'courierID': courierID,
      'brokerID': brokerID,
      'nodeID': nodeID,
    };
  }

  static Milestone fromMap(Map<String, dynamic> map) {
    return Milestone(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTimeAndDate: map['startTimeAndDate'] ?? '',
      endTimeAndDate: map['endTimeAndDate'] ?? '',
      courierID: map['courierID'] ?? '',
      brokerID: map['brokerID'] ?? '',
      nodeID: map['nodeID'] ?? '',
    );
  }
}