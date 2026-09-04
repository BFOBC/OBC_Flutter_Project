import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateMilestone {
  final String title;
  final String description;

  TemplateMilestone({required this.title, required this.description});

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
      };

  factory TemplateMilestone.fromMap(Map<String, dynamic> map) =>
      TemplateMilestone(
        title: map['title'] ?? '',
        description: map['description'] ?? '',
      );
}

class TemplateModel {
  final String? templateId;
  final String templateName;
  final String startDateTime;
  final String endDateTime;
  final String departureFrom;
  final String arriveAt;
  final String bid;
  final String currency;
  final String courierCapacity;
  final String unit;
  final String userId;
  final List<TemplateMilestone> milestones;

  TemplateModel({
    this.templateId,
    required this.templateName,
    required this.startDateTime,
    required this.endDateTime,
    required this.departureFrom,
    required this.arriveAt,
    required this.bid,
    required this.currency,
    required this.courierCapacity,
    required this.unit,
    required this.userId,
    this.milestones = const [],
  });

  Map<String, dynamic> toMap() => {
        'templateName': templateName,
        'startDateTime': startDateTime,
        'endDateTime': endDateTime,
        'departureFrom': departureFrom,
        'arriveAt': arriveAt,
        'bid': bid,
        'currency': currency,
        'courierCapacity': courierCapacity,
        'unit': unit,
        'userId': userId,
        'milestones': milestones.map((m) => m.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory TemplateModel.fromMap(String id, Map<String, dynamic> map) =>
      TemplateModel(
        templateId: id,
        templateName: map['templateName'] ?? '',
        startDateTime: map['startDateTime'] ?? '',
        endDateTime: map['endDateTime'] ?? '',
        departureFrom: map['departureFrom'] ?? '',
        arriveAt: map['arriveAt'] ?? '',
        bid: map['bid'] ?? '',
        currency: map['currency'] ?? '',
        courierCapacity: map['courierCapacity'] ?? '',
        unit: map['unit'] ?? '',
        userId: map['userId'] ?? '',
        milestones: (map['milestones'] as List<dynamic>? ?? [])
            .map((m) =>
                TemplateMilestone.fromMap(m as Map<String, dynamic>))
            .toList(),
      );
}
