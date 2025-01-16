class Milestone {
  final String title;
  final String description;
  final String milestoneStartDateTime;
  final String milestoneEndDateTime;
  final String? courierID;
  final String? brokerID;
  String? milestoneNodeID;

  Milestone({
    required this.title,
    required this.description,
    required this.milestoneStartDateTime,
    required this.milestoneEndDateTime,
    this.courierID,
    this.brokerID,
    this.milestoneNodeID,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'milestoneStartDateTime': milestoneStartDateTime,
      'milestoneEndDateTime': milestoneEndDateTime,
      'courierID': courierID,
      'brokerID': brokerID,
      'milestoneNodeID': milestoneNodeID,
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
      milestoneNodeID: map['milestoneNodeID'] ?? '',
    );
  }
}