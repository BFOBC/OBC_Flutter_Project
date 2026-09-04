import 'package:cloud_firestore/cloud_firestore.dart';

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
      );

  TemplateModel copyWith({
    String? templateId,
    String? templateName,
    String? startDateTime,
    String? endDateTime,
    String? departureFrom,
    String? arriveAt,
    String? bid,
    String? currency,
    String? courierCapacity,
    String? unit,
    String? userId,
  }) =>
      TemplateModel(
        templateId: templateId ?? this.templateId,
        templateName: templateName ?? this.templateName,
        startDateTime: startDateTime ?? this.startDateTime,
        endDateTime: endDateTime ?? this.endDateTime,
        departureFrom: departureFrom ?? this.departureFrom,
        arriveAt: arriveAt ?? this.arriveAt,
        bid: bid ?? this.bid,
        currency: currency ?? this.currency,
        courierCapacity: courierCapacity ?? this.courierCapacity,
        unit: unit ?? this.unit,
        userId: userId ?? this.userId,
      );
}
