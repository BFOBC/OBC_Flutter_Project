class Rating {
  String ratingID;
  String courierID;
  String brokerID;
  final String jobID;
  final String jobType;
  final double rating;
  final String dateTime;
  final String comment;
  final String from;

  Rating({
    required this.ratingID,
    required this.courierID,
    required this.brokerID,
    required this.jobID,
    required this.jobType,
    required this.rating,
    required this.dateTime,
    required this.comment,
    required this.from,
  });

  // Convert Rating object to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'ratingID': ratingID,
      'courierID': courierID,
      'brokerID': brokerID,
      'jobID': jobID,
      'jobType': jobType,
      'rating': rating,
      'dateTime': dateTime,
    };
  }

  // Convert a Map to a Rating object (for retrieving from Firestore)
  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      ratingID: map['ratingID'] ?? '',
      courierID: map['courierID'] ?? '',
      brokerID: map['brokerID'] ?? '',
      jobID: map['jobID'] ?? '',
      jobType: map['jobType'] ?? '',
      rating: map['rating'] ?? '',
      dateTime: map['dateTime'] ?? '',
      comment: map['comment'] ?? '',
      from: map['from'] ?? '',
    );
  }
}
