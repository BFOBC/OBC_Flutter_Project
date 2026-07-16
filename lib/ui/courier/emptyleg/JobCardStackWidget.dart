import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:broker_flutter_pp/ui/courier/emptyleg/AddEmptyLegDialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class JobCardStackWidget extends StatefulWidget {
  const JobCardStackWidget({Key? key}) : super(key: key);

  @override
  _JobCardStackWidgetState createState() => _JobCardStackWidgetState();
}

class _JobCardStackWidgetState extends State<JobCardStackWidget> {
  List<Map<String, dynamic>> jobs = [];
  bool isLoading = true;

  // List of user-entered flight details
  List<FlightDetails> userEnteredFlightDetailsList = [];
  String? emptyLegNodeID;
  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      print('📦 Courier ID (UID): ${user.uid}');

      final snapshot = await FirebaseFirestore.instance
          .collection('emptyLegs')
          .where('courierID', isEqualTo: user.uid)
          // .orderBy('fromDateTime', descending: true)
          .get();

      final jobList = snapshot.docs.map((doc) {
        final data = doc.data();

        String getString(dynamic value, {String fallback = ''}) {
          return value is String ? value : fallback;
        }

        return {
          'emptyLegNodeID': doc.id,
          'fromLocation': getString(data['fromLocation'], fallback: 'Unknown'),
          'toLocation': getString(data['toLocation'], fallback: 'Unknown'),
          'fromDateTime': getString(data['fromDateTime']),
          'toDateTime': getString(data['toDateTime']),
          'flightNumber': getString(data['flightNumber']),
          'capacity': getString(data['capacity']),
        };
      }).toList();

      setState(() {
        jobs.clear();
        jobs = jobList;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching jobs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox.expand(
      child: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : jobs.isEmpty
              ? Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded, size: 60, color: Colors.redAccent),

                  Text(
                    'No Empty Legs Available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Click below button to add new',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          )

              : ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];

              return Dismissible(
                key: Key(job['emptyLegNodeID'] ?? UniqueKey().toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),

                // ⛔ Confirm Dismiss before actually deleting
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: Colors.white,
                        elevation: 10,
                        titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
                        title: Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text(
                              'Confirm Deletion',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        content: const Text(
                          'Are you sure you want to delete this job? This action cannot be undone.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                },

                // ✅ Dismiss only if confirmDismiss returned true
                onDismissed: (direction) {
                  String nodeId = job['emptyLegNodeID'] ?? '';

                  // 🔥 Firebase se delete karo
                  deleteEmptyLegFromFirebase(nodeId);

                  // 🧹 Local list se delete karo
                  setState(() {
                    jobs.removeAt(index);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.delete_forever, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(child: Text('Empty Leg Deleted')),
                        ],
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'Deleted',
                        textColor: Colors.white,
                        onPressed: () {
                          // 🔄 Undo logic here
                        },
                      ),
                    ),
                  );

                },

                child: GestureDetector(
                  onTap: () {
                    FlightDetails flightDetails = FlightDetails(
                      fromLocation: job['fromLocation'] ?? '',
                      toLocation: job['toLocation'] ?? '',
                      fromDateTime: job['fromDateTime'] ?? '',
                      toDateTime: job['toDateTime'] ?? '',
                      flightNumber: job['flightNumber'] ?? '',
                      capacity: job['capacity']?.toString() ?? '',
                      userName: job['userName'] ?? '',
                      rating: int.tryParse(job['rating']?.toString() ?? '0') ?? 0,
                    );

                    emptyLegNodeID = job['emptyLegNodeID'] ?? 'N/A';

                    _showFlightDetailsDialog(
                      context,
                      flightDetails,
                      index,
                      true,
                      emptyLegNodeID.toString(),
                    );
                  },
                  child: _buildJobCard(job, screenWidth),
                ),
              );

            },
          ),

          // ✅ Floating Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      FlightDetails flightDetails = FlightDetails.empty();
                      _showFlightDetailsDialog(
                        context,
                        flightDetails,
                        -1,
                        false,
                        emptyLegNodeID.toString(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Empty Leg"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteEmptyLegFromFirebase(String nodeId) async {
    try {
      print('Attempting to delete from Firestore: $nodeId');

      await FirebaseFirestore.instance
          .collection("emptyLegs")
          .doc(nodeId)
          .delete();

      print('✅ Successfully deleted from Firestore: $nodeId');
    } catch (e) {
      print('❌ Error deleting from Firestore: $e');
    }
  }


  // Function to show a dialog for flight details (add/update)
  void _showFlightDetailsDialog(
      BuildContext context,
      FlightDetails flightDetails,
      int index,
      bool isUpdate,
      String emptyLegNodeID,
      ) async {
    final result = await showDialog(
      context: context,
      builder: (context) => FlightDetailsDialog(
        flightDetails: flightDetails,
        flightIndex: index,
        isUpdate: isUpdate,
        emptyLegID: emptyLegNodeID,
      ),
    );

    // ✅ Jab dialog band ho jaye
    if (result != null) {
      // 🔄 Refresh kar do jobs list
      setState(() {
        _fetchJobs(); // Or your data fetching logic
      });
    }
    setState(() {
      _fetchJobs(); // Or your data fetching logic
    });
  }

  Widget _buildJobCard(Map<String, dynamic> job, double screenWidth) {
    String formatDate(String utcString) {
      try {
        final dateTime =
            DateTime.parse(utcString).toLocal(); // Convert from UTC to local
        return DateFormat('dd MMMM yyyy').format(dateTime);
      } catch (e) {
        return 'Invalid Date';
      }
    }

    String formatTime(String utcString) {
      try {
        final dateTime = DateTime.parse(utcString).toLocal();
        return DateFormat('hh:mm a').format(dateTime);
      } catch (e) {
        return 'Invalid Time';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Slightly more symmetric
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Softer corners
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // Internal padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "✈️ Flight: ${job['flightNumber'] ?? 'N/A'}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _buildInfo("📍 From", job['fromLocation']),
                  _buildInfo("📍 To", job['toLocation']),
                  _buildInfo("📅 From Date", formatDate(job['fromDateTime'])),
                  _buildInfo("🕒 From Time", formatTime(job['fromDateTime'])),
                  _buildInfo("📅 To Date", formatDate(job['toDateTime'])),
                  _buildInfo("🕒 To Time", formatTime(job['toDateTime'])),
                  _buildInfo("🧳 Capacity", job['capacity']),
                ],
              ),
            ],
          ),
        ),
      ),
    );

  }
  Widget _buildInfo(String label, String? value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        children: [
          TextSpan(
            text: "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value ?? 'N/A'),
        ],
      ),
    );
  }

}

class FlightDetails {
  String fromLocation;
  String toLocation;
  String fromDateTime;
  String toDateTime;
  String flightNumber;
  String capacity;
  String? userName; // <-- made nullable
  int rating;

  FlightDetails({
    required this.fromLocation,
    required this.toLocation,
    required this.fromDateTime,
    required this.toDateTime,
    required this.flightNumber,
    required this.capacity,
    this.userName, // <-- not required now
    required this.rating,
  });

  factory FlightDetails.empty() {
    return FlightDetails(
      fromLocation: '',
      toLocation: '',
      fromDateTime: '',
      toDateTime: '',
      flightNumber: '',
      capacity: '',
      userName: null,
      // or leave it out
      rating: 0,
    );
  }

  factory FlightDetails.fromMap(Map<String, dynamic> map) {
    return FlightDetails(
      userName: map['userName'],
      // No fallback needed
      rating: (map['rating'] ?? 0).toInt(),
      fromLocation: map['fromLocation'] ?? '',
      toLocation: map['toLocation'] ?? '',
      fromDateTime: map['fromDateTime'] ?? '',
      toDateTime: map['toDateTime'] ?? '',
      flightNumber: map['flightNumber'] ?? '',
      capacity: map['capacity'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'fromDateTime': fromDateTime,
      'toDateTime': toDateTime,
      'flightNumber': flightNumber,
      'capacity': capacity,
      if (userName != null) 'userName': userName,
      'rating': rating,
    };
  }
}
