import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';

class Milestone {
  final String title;
  final String description;
  String? milestoneStartDateTime;
  String? milestoneEndDateTime;
  final String? courierID;
  final String? brokerID;
  String? milestoneNodeID;
  String? milestoneStatus;
  String? emptyLegRequestID;

  Milestone({
    required this.title,
    required this.description,
    required this.milestoneStartDateTime,
    required this.milestoneEndDateTime,
    this.courierID,
    this.brokerID,
    this.milestoneNodeID,
    this.milestoneStatus,
    this.emptyLegRequestID,
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
      'milestoneStatus': milestoneStatus,
      'emptyLegRequestID': emptyLegRequestID,
    };
  }

  static Milestone fromMap(Map<String, dynamic> map) {
    return Milestone(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      milestoneStartDateTime: map['milestoneStartDateTime'] ?? '',
      milestoneEndDateTime: map['milestoneEndDateTime'] ?? '',
      courierID: map['courierID'] ?? '',
      brokerID: map['brokerID'] ?? '',
      milestoneNodeID: map['milestoneNodeID'] ?? '',
      milestoneStatus: map['milestoneStatus'] ?? '',
      emptyLegRequestID: map['emptyLegRequestID'] ?? '',
    );
  }
  // Getters for local time conversion
  String get localStartDateTime => convertUTCToLocal(milestoneStartDateTime ?? '');
  String get localEndDateTime => convertUTCToLocal(milestoneEndDateTime ?? '');
}