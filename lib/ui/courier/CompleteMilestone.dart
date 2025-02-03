import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../common/utils/RoleProvider.dart';

class CompleteMilestone extends StatefulWidget {
  final String selectedTab;
  final Task task;

  // Constructor to accept selectedTab and task
  CompleteMilestone({Key? key, required this.selectedTab, required this.task}) : super(key: key);

  @override
  _CompleteMilestoneState createState() => _CompleteMilestoneState();
}

class _CompleteMilestoneState extends State<CompleteMilestone> {
  late Future<List<Milestone>> milestonesFuture;

  @override
  void initState() {
    super.initState();
    milestonesFuture = _fetchMilestones();  // Fetch the milestones when the screen loads
  }

  // Method to fetch milestones based on emptyLegCourierID
  Future<List<Milestone>> _fetchMilestones() async {
    final firestoreService = FirestoreService(context);
    return await firestoreService.getMilestonesByEmptyLegCourierID(widget.task.emptyLegRequestID!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Milestone>>(
        future: milestonesFuture,  // Use FutureBuilder to manage the async data loading
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final milestones = snapshot.data ?? [];

          if (milestones.isEmpty) {
            return const Center(child: Text("No milestones available"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final milestone = milestones[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: milestone.milestoneStatus == "Done"
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.rectangle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              milestone.title ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Description: ${milestone.description ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Text('Start: ${milestone.milestoneStartDateTime ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Text('End: ${milestone.milestoneEndDateTime ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Text('Status: ${milestone.milestoneStatus ?? 'N/A'}'), // Display status
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          _showMilestoneDialog(context, milestone);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(color: Colors.white), // Set text color to white
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMilestoneDialog(BuildContext context, Milestone milestone) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Milestone Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Title: ${milestone.title}'),
                    const SizedBox(height: 10),
                    Text('Description: ${milestone.description}'),
                    const SizedBox(height: 10),
                    Text('Start Time: ${milestone.milestoneStartDateTime}'),
                    const SizedBox(height: 10),
                    Text('End Time: ${milestone.milestoneEndDateTime}'),
                    const SizedBox(height: 10),
                    Text('Status: ${milestone.milestoneStatus}'),
                    const SizedBox(height: 20),
                    Center(
                      child: widget.selectedTab == "In Progress" &&
                          FirebaseAuth.instance.currentUser != null &&
                          roleProvider.role == UserRole.courier // Only show "Mark as Done" for couriers
                          ? ElevatedButton(
                        onPressed: milestone.milestoneStatus == "Completed"
                            ? null
                            : () {
                          final firestoreService = FirestoreService(context);
                          // Update job status
                          firestoreService.updateMilestoneStatus(milestone.milestoneNodeID.toString(), "Completed");

                          String milestoneID = milestone.milestoneNodeID.toString();
                          final User currentUser = FirebaseAuth.instance.currentUser!;
                          String email = currentUser.email!;
                          firestoreService.createNotification(
                            brokerID: milestone.brokerID!,
                            courierID: currentUser.uid,
                            emptyLegRequestID: widget.task.emptyLegRequestID.toString(),
                            sentBy: "Courier",
                            message: milestone.milestoneNodeID.toString(),
                            milestoneID: "Your Milestone $milestoneID is Completed by $email",
                          );

                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Mark as Done',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                          : Container(), // Hide the "Mark as Done" button for non-couriers
                    ),
                    // Center the "Close" button if user is not broker
                    if (roleProvider.role != UserRole.broker)
                      Align(
                        alignment: Alignment.center, // Center the button
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Always visible close icon
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
