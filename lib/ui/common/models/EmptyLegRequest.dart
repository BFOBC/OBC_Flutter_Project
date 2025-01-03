import 'package:broker_flutter_pp/ui/common/utils/CustomDialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:path/path.dart';

class EmptyLegRequest {
  final String brokerID;
  final String courierID;
  String? nodeID; // Make nodeID nullable
  final String requestDateTime;
  final String? status;
  final String? milestoneNodeID;
  final String? startTimeDate;
  final String? endTimeDate;
  final String? departureLocation;
  final String? arrivalLocation;
  final String? bid;
  final String? courierCapacity;

  // Constructor
  EmptyLegRequest({
    required this.brokerID,
    required this.courierID,
    required this.nodeID, // Updated to allow null initially
    required this.requestDateTime,
    required this.status,
    required this.milestoneNodeID,
    this.startTimeDate,
    this.endTimeDate,
    this.departureLocation,
    this.arrivalLocation,
    this.bid,
    this.courierCapacity,
  });

  // Convert model to a map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'brokerID': brokerID,
      'courierID': courierID,
      'nodeID': nodeID ?? '', // Save as empty string if null
      'requestDateTime': requestDateTime,
      'status': status,
      'milestoneNodeID': milestoneNodeID,
      'startTimeDate': startTimeDate,
      'endTimeDate': endTimeDate,
      'departureLocation': departureLocation,
      'arrivalLocation': arrivalLocation,
      'bid': bid,
      'courierCapacity': courierCapacity,
    };
  }

  // Create an object from a map
  static EmptyLegRequest fromMap(Map<String, dynamic> map) {
    return EmptyLegRequest(
      brokerID: map['brokerID'] ?? '',
      courierID: map['courierID'] ?? '',
      nodeID: map['nodeID'], // Nullable, don't default to empty string
      requestDateTime: map['requestDateTime'] ?? '',
      status: map['status'] ?? 'status',
      milestoneNodeID: map['milestoneNodeID'],
      startTimeDate: map['startTimeDate'],
      endTimeDate: map['endTimeDate'],
      departureLocation: map['departureLocation'],
      arrivalLocation: map['arrivalLocation'],
      bid: map['bid'],
      courierCapacity: map['courierCapacity'],
    );
  }

}


