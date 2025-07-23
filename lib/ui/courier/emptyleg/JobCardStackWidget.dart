import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:broker_flutter_pp/ui/courier/emptyleg/AddEmptyLegDialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      // ⬅️ Makes the Stack take full screen
      child: Stack(
        children: [
          // ✅ Job list or loading indicator
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : jobs.isEmpty
                  ? const Center(child: Text("No jobs found"))
                  : ListView.builder(
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];

                        return GestureDetector(
                          onTap: () {
                            // 👉 Step 1: FlightDetails object banayein list item se
                            FlightDetails flightDetails = FlightDetails(
                              fromLocation: job['fromLocation'] ?? '',
                              toLocation: job['toLocation'] ?? '',
                              fromDateTime: job['fromDateTime'] ?? '',
                              toDateTime: job['toDateTime'] ?? '',
                              flightNumber: job['flightNumber'] ?? '',
                              capacity: job['capacity']?.toString() ?? '',
                              userName: job['userName'] ?? '',
                              rating: int.tryParse(
                                      job['rating']?.toString() ?? '0') ??
                                  0,
                            );
                            emptyLegNodeID=job['emptyLegNodeID'] ?? 'N/A';

                            // 👉 Step 2: Dialog show karein
                            _showFlightDetailsDialog(
                                context, flightDetails, index, true,emptyLegNodeID.toString());
                          },
                          child: _buildJobCard(job, screenWidth),
                        );
                      },
                    ),

// ✅ Floating Button fixed at bottom center, above gesture/nav bar
          Positioned(
            bottom: 0, // ⬅️ This is the missing piece!
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
                      if (flightDetails != null) {
                        _showFlightDetailsDialog(
                            context, flightDetails, -1, false,emptyLegNodeID.toString());
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Empty Leg"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            // ✅ Allows card to be scrollable if needed
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      "✈️ Flight: ${job['flightNumber']}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(
                              text: "📍 From: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: job['fromLocation'] ?? 'N/A'),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(
                              text: "📍 To: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: job['toLocation'] ?? 'N/A'),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(
                              text: "📅 From Date: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: formatDate(job['fromDateTime'])),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(
                              text: "🕒 From Time: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: formatTime(job['fromDateTime'])),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(
                              text: "📅 To Date: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: formatDate(job['toDateTime'])),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(
                              text: "🕒 To Time: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: formatTime(job['toDateTime'])),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(
                              text: "🚛 Capacity: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: job['capacity'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
