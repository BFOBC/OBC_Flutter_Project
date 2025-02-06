import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/CustomDialog.dart';
import 'package:broker_flutter_pp/ui/common/widgets/RatingDialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../common/utils/RoleProvider.dart';

class CompleteMilestone extends StatefulWidget {
  final String selectedTab;
  final Task task;

  // Constructor to accept selectedTab and task
  CompleteMilestone({Key? key, required this.selectedTab, required this.task})
      : super(key: key);

  @override
  _CompleteMilestoneState createState() => _CompleteMilestoneState();
}

class _CompleteMilestoneState extends State<CompleteMilestone> {
  late Future<List<Milestone>> milestonesFuture;

  @override
  void initState() {
    super.initState();
    milestonesFuture =
        _fetchMilestones(); // Fetch the milestones when the screen loads
  }

  // Method to fetch milestones based on emptyLegCourierID
  Future<List<Milestone>> _fetchMilestones() async {
    final firestoreService = FirestoreService(context);
    return await firestoreService
        .getMilestonesByEmptyLegCourierID(widget.task.emptyLegRequestID!);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Milestone>>(
        future: milestonesFuture,
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

          // Check if there's any milestone with title 'Pending'
          bool hasPendingMilestone = milestones.any((milestone) => milestone.milestoneStatus == 'Pending');

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
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
                                  Text(
                                      'Description: ${milestone.description ?? 'N/A'}'),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Start: ${milestone.milestoneStartDateTime ?? 'N/A'}'),
                                  const SizedBox(height: 4),
                                  Text(
                                      'End: ${milestone.milestoneEndDateTime ?? 'N/A'}'),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Status: ${milestone.milestoneStatus ?? 'N/A'}'),
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
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Conditionally show the Complete Job button
              if (hasPendingMilestone)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0), // More bottom spacing
                  child: SizedBox(
                    width: double.infinity, // Makes the button take full width
                    child: ElevatedButton(
                      onPressed: () {
                        showJobCompletionDialog(context, milestonesFuture);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primaryColor, // Green background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // More rounded corners for a modern look
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10.0), // Increased vertical padding
                        elevation: 4, // Adds slight shadow for better visibility
                      ),
                      child: const Text(
                        'Complete Job',
                        style: TextStyle(
                          color: Colors.white, // White text color
                          fontSize: 15, // Slightly larger font
                          fontWeight: FontWeight.w600, // Semi-bold for better readability
                          letterSpacing: 1.0, // Adds slight spacing for aesthetics
                        ),
                      ),
                    ),
                  ),
                ),

            ],
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
                          roleProvider.role ==
                              UserRole
                                  .courier // Only show "Mark as Done" for couriers
                          ? ElevatedButton(
                        onPressed: milestone.milestoneStatus ==
                            "Completed"
                            ? null
                            : () {
                          final firestoreService =
                          FirestoreService(context);

                          // Update job status
                          firestoreService
                              .updateMilestoneStatus(
                              milestone.milestoneNodeID
                                  .toString(),
                              "Completed")
                              .then((_) {
                            // Once the status is updated, refresh the data by calling setState
                            setState(() {
                              milestonesFuture =
                                  _fetchMilestones(); // Re-fetch milestones after update
                            });

                            String milestoneID = milestone
                                .milestoneNodeID
                                .toString();
                            final User currentUser =
                            FirebaseAuth.instance.currentUser!;
                            String email = currentUser.email!;

                            firestoreService.createNotification(
                              brokerID: milestone.brokerID!,
                              courierID: currentUser.uid,
                              emptyLegRequestID: widget
                                  .task.emptyLegRequestID
                                  .toString(),
                              sentBy: "Courier",
                              message: milestone.milestoneNodeID
                                  .toString(),
                              milestoneID:
                              "Your Milestone $milestoneID is Completed by $email",
                            );

                            Navigator.of(context)
                                .pop(); // Close the dialog
                          });
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
                    if (roleProvider.role != UserRole.courier)
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
                    icon:
                    const Icon(Icons.close, color: Colors.white, size: 16),
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

// Method to complete the job
  Future<void> completeJob(BuildContext context, String brokerID, String emptyLegRequestID) async {
    final FirestoreService service = FirestoreService(context);

    try {
      // Mark the job as completed
      await service.updateJobStatus(emptyLegRequestID, 'Completed');

      // Prepare notification message
      final User currentUser = FirebaseAuth.instance.currentUser!;
      final String email = currentUser.email ?? 'Unknown User';
      final String message = "Your Job has been completed by $email";

      // Create notification after job completion
      await service.createNotification(
        brokerID: brokerID,
        courierID: currentUser.uid,
        emptyLegRequestID: emptyLegRequestID,
        sentBy: "Courier",
        message: message,
      );

      // Show custom success dialog
      CustomDialog.showCustomDialog3(
        context,
        "Job Completed Successfully",
        onOkPressed: () async {
          // Close the current job completion dialog
          Navigator.of(context).pop();

          // After the success dialog is dismissed, trigger the rating dialog
          await showDialog(
            context: context,
            builder: (context) => RatingDialog(
              brokerName: "John Doe",
              brokerImage: "https://via.placeholder.com/150", // Dummy Image URL
            ),
          );
        },
      );
    } catch (e) {
      // Handle any errors during the job completion process
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to complete the job: $e'),
        backgroundColor: Colors.red,
      ));
    }
}

// Method to show the job completion alert dialog
  void showJobCompletionDialog(BuildContext context,
      Future<List<Milestone>> milestonesFuture) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Milestone>>(
          future: milestonesFuture, // Use the passed Future directly
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(child: Text('No milestones available.'));
            }

            List<Milestone> milestones = snapshot.data!;
            List<Milestone> pendingMilestones = milestones
                .where((milestone) => milestone.milestoneStatus == 'Pending')
                .toList();

            // If there are pending milestones
            if (pendingMilestones.isNotEmpty) {
              return AlertDialog(
                title: Text(
                  'Job Completion Status',
                  style: TextStyle(
                    fontSize: 18, // Reduced title size
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'You are about to complete this job as the following milestones are pending:'),
                    SizedBox(height: 10),
                    // Display the titles of the pending milestones with numbering
                    ...pendingMilestones
                        .asMap()
                        .entries
                        .map((entry) {
                      int index = entry.key + 1; // Start from 1 instead of 0
                      String title = entry.value.title ?? 'Unknown Milestone';
                      return Text('$index) $title');
                    }).toList(),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Show a loading indicator or wait for the job completion to be processed.
                      try {
                        // Call your Firebase method to complete the job (example Firebase call)
                        await completeJob(context, widget.task.brokerId
                            .toString(), widget.task.emptyLegRequestID
                            .toString());
                        await Future.delayed(Duration(seconds: 5)); // Delay for 1 second to ensure the job is completed
                        Navigator.of(context).pop(); // Close the current dialog after completing the job
                      } catch (e) {
                        // Handle any errors here (e.g., show an error message)
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Failed to complete the job: $e'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors
                          .red, // Set background color to red
                    ),
                    child: Text(
                      'Complete Job',
                      style: TextStyle(
                          color: Colors.white), // Set text color to white
                    ),
                  ),
                ],
              );
            } else {
              // If no pending milestones, show rating dialog
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  builder: (context) =>
                      RatingDialog(
                        brokerName: "John Doe",
                        brokerImage: "https://via.placeholder.com/150", // Dummy Image URL
                      ),
                );
              });

              return SizedBox(); // Return empty widget until the dialog is triggered
            }
          },
        );
      },
    );
  }
}

