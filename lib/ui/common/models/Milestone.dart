class Milestone {
  final String title;
  final String description;
  final String milestoneStartDateTime;
  final String milestoneEndDateTime;
  final String? courierID;
  final String? brokerID;
  String? nodeID;

  Milestone({
    required this.title,
    required this.description,
    required this.milestoneStartDateTime,
    required this.milestoneEndDateTime,
    this.courierID,
    this.brokerID,
    this.nodeID,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'milestoneStartDateTime': milestoneStartDateTime,
      'milestoneEndDateTime': milestoneEndDateTime,
      'courierID': courierID,
      'brokerID': brokerID,
      'nodeID': nodeID,
    };
  }

  static Milestone fromMap(Map<String, dynamic> map) {
    return Milestone(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      milestoneStartDateTime: map['milestoneStartDateTime'] ?? '',
      milestoneEndDateTime: map['endTimeAndDate'] ?? '',
      courierID: map['courierID'] ?? '',
      brokerID: map['brokerID'] ?? '',
      nodeID: map['nodeID'] ?? '',
    );
  }
}