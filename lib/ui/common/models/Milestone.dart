class Milestone {
  final String jobID;
  final String courierID;
  final String milestoneID;
  final String title;
  final String startDateTime;
  final String endDateTime;
  final String description;
  final String status; // completed - in progress - todo

  Milestone({
    required this.jobID,
    required this.courierID,
    required this.milestoneID,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.description,
    required this.status,
  });
}
