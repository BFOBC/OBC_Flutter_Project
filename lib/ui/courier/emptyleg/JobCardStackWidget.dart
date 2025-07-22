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

        int getInt(dynamic value, {int fallback = 5}) {
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) {
            return int.tryParse(value) ?? fallback;
          }
          return fallback;
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

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : jobs.isEmpty
        ? const Center(child: Text("No jobs found"))
        : SizedBox(
      height: MediaQuery.of(context).size.height * 0.3,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          return _buildJobCard(jobs[index], screenWidth);
        },
      ),
    );
  }


  Widget _buildJobCard(Map<String, dynamic> job, double screenWidth) {
    String formatDate(String utcString) {
      try {
        final dateTime = DateTime.parse(utcString).toLocal(); // Convert from UTC to local
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
          child: SingleChildScrollView( // ✅ Allows card to be scrollable if needed
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
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(text: "📍 From: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: job['fromLocation'] ?? 'N/A'),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(text: "📍 To: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: job['toLocation'] ?? 'N/A'),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(text: "📅 From Date: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: formatDate(job['fromDateTime'])),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(text: "🕒 From Time: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: formatTime(job['fromDateTime'])),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(text: "📅 To Date: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: formatDate(job['toDateTime'])),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(text: "🕒 To Time: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: formatTime(job['toDateTime'])),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(text: "🚛 Capacity: ", style: TextStyle(fontWeight: FontWeight.bold)),
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
