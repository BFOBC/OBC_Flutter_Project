import 'package:broker_flutter_pp/ui/common/utils/CustomDialog.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:path/path.dart';

class EmptyLegRequest {
  final String brokerID;
  final String courierID;
  String? emptyLegRequestID; // Make nodeID nullable
  final String requestDateTime;
  final String? status;
  final List<String?> milestoneNodeIDs; // Changed to List<String?>
  String? startTimeDate;
  String? endTimeDate;
  final String? departureLocation;
  final String? arrivalLocation;
  final String? bid;
  final String? courierCapacity;
  final String? isBrokerRated;
  final String? isCourierRated;
  final String? emptyLegTBLNodeID;

  // Constructor
  EmptyLegRequest({
    required this.brokerID,
    required this.courierID,
    required this.emptyLegRequestID, // Updated to allow null initially
    required this.requestDateTime,
    required this.status,
    required this.milestoneNodeIDs, // Changed to accept a list
    this.startTimeDate,
    this.endTimeDate,
    this.departureLocation,
    this.arrivalLocation,
    this.bid,
    this.courierCapacity,
    this.isBrokerRated,
    this.isCourierRated,
    this.emptyLegTBLNodeID,
  });

  // ✅ Convert model to a map for Firestore
  Map<String, dynamic> toJson() {
    dynamic _stringOrTimestamp(String? isoString) {
      if (isoString == null || isoString.isEmpty) return null;
      try {
        final dt = DateTime.parse(isoString);
        return Timestamp.fromDate(dt);
      } catch (e) {
        return isoString;
      }
    }

    return {
      'brokerID': brokerID,
      'courierID': courierID,
      'emptyLegRequestID': emptyLegRequestID ?? '',
      'requestDateTime': _stringOrTimestamp(requestDateTime),
      'status': status,
      'milestoneNodeIDs': milestoneNodeIDs,
      'startTimeDate': _stringOrTimestamp(startTimeDate),
      'endTimeDate': _stringOrTimestamp(endTimeDate),
      'departureLocation': departureLocation,
      'arrivalLocation': arrivalLocation,
      'bid': bid,
      'courierCapacity': courierCapacity,
      'isCourierRated': isCourierRated,
      'isBrokerRated': isBrokerRated,
      'emptyLegTBLNodeID': emptyLegTBLNodeID,
    };
  }

  // ✅ Create an object from a map
  static EmptyLegRequest fromMap(Map<String, dynamic> map) {
    String? _asIsoString(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate().toIso8601String();
      } else if (value is DateTime) {
        return value.toIso8601String();
      } else {
        return value.toString();
      }
    }

    bool _asBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      final s = value.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    List<String> _asStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      if (value is String) {
        return value.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    print('🟢 Mapping EmptyLegRequest from Firestore data: $map');

    return EmptyLegRequest(
      brokerID: map['brokerID'] ?? '',
      courierID: map['courierID'] ?? '',
      emptyLegRequestID: map['emptyLegRequestID'],
      requestDateTime: _asIsoString(map['requestDateTime']) ?? '',
      status: map['status'] ?? 'status',
      milestoneNodeIDs: _asStringList(map['milestoneNodeIDs']),
      startTimeDate: _asIsoString(map['startTimeDate']),
      endTimeDate: _asIsoString(map['endTimeDate']),
      departureLocation: map['departureLocation'],
      arrivalLocation: map['arrivalLocation'],
      bid: map['bid']?.toString(),
      courierCapacity: map['courierCapacity']?.toString(),
      isBrokerRated: _asBool(map['isBrokerRated']).toString(),
      isCourierRated: _asBool(map['isCourierRated']).toString(),
      emptyLegTBLNodeID: map['emptyLegTBLNodeID'],
    );
  }

  // ✅ Getters for local time conversion
  String get localStartDateTime => convertUTCToLocal(startTimeDate ?? '');
  String get localEndDateTime => convertUTCToLocal(endTimeDate ?? '');
}
