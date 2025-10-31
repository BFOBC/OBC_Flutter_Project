
import 'package:broker_flutter_pp/data/NotificationService.dart';
import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/CustomDialog.dart';
import 'package:broker_flutter_pp/ui/common/widgets/RatingDialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../common/utils/RoleProvider.dart';

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
  List<Milestone> _milestones = []; // ✅ Define the list

  @override
  void initState() {
    super.initState();
    milestonesFuture = _fetchMilestones();
  }

  Future<List<Milestone>> _fetchMilestones() async {
    final firestoreService = FirestoreService(context);
    List<Milestone> milestones = await firestoreService.getMilestonesByEmptyLegCourierID(
      widget.task.emptyLegRequestID!,
    );

    if (mounted) {
      setState(() {
        _milestones = milestones;
      });

      // Check if all milestones are completed
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      if (roleProvider.role == UserRole.courier && widget.selectedTab == "In Progress") {
        _checkAndCompleteJob();
      }
    }

    return milestones; // ✅ Return the fetched milestones
  }

  void _checkAndCompleteJob() {
    bool allCompleted = _milestones.isNotEmpty && _milestones.every((m) => m.milestoneStatus == "Completed");

    print("allCompleted: $allCompleted");

    if (allCompleted) {
      // Add a slight delay before calling completeJob to ensure smooth UI transition
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          completeJob(context, widget.task.brokerId!, widget.task.emptyLegRequestID.toString());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _milestones.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _milestones.length,
              itemBuilder: (context, index) {
                final milestone = _milestones[index];
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
                                color: milestone.milestoneStatus == "Completed"
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
                              Text('Start: ${milestone.localStartDateTime ?? 'N/A'}'),
                              const SizedBox(height: 4),
                              Text('End: ${milestone.localEndDateTime ?? 'N/A'}'),
                              const SizedBox(height: 4),
                              Text('Status: ${milestone.milestoneStatus ?? 'N/A'}'),
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
          if (_milestones.any((m) => m.milestoneStatus == 'Pending'))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showJobCompletionDialog(context, Future.value(_milestones));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Complete Job',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
          backgroundColor: Colors.white,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.flag, color: Colors.blue, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Milestone Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(thickness: 1, height: 20),
                    const SizedBox(height: 10),
                    _buildInfoRow('📌 Title:', milestone.title),
                    _buildInfoRow('📝 Description:', milestone.description),
                    _buildInfoRow('⏰ Start Time:', milestone.localStartDateTime),
                    _buildInfoRow('⏳ End Time:', milestone.localEndDateTime),
                    _buildInfoRow('📍 Status:', milestone.milestoneStatus),
                    const SizedBox(height: 15),
                    Center(
                      child: widget.selectedTab == "In Progress" &&
                          FirebaseAuth.instance.currentUser != null &&
                          roleProvider.role == UserRole.courier
                          ? ElevatedButton.icon(
                        onPressed: milestone.milestoneStatus == "Completed"
                            ? null
                            : () async {
                          final firestoreService = FirestoreService(context);

                          await firestoreService.updateMilestoneStatus(
                            milestone.milestoneNodeID.toString(),
                            "Completed",
                          );

                          setState(() {
                            milestonesFuture = _fetchMilestones();
                          });

                          String milestoneID = milestone.milestoneNodeID.toString();
                          final User currentUser = FirebaseAuth.instance.currentUser!;
                          String email = currentUser.email!;

                          //send milestone completed notification
                          final brokerData = await NotificationService.getBrokerNameAndTokenById(widget.task.brokerId.toString());
                          final courierData = await NotificationService.getCourierNameAndTokenById(currentUser.uid.toString());

                          print("brokerData: Notification sent$brokerData");

                          if (brokerData != null) {
                            await NotificationService.sendNotification(
                              title: "Milestone Completed",
                              toToken: brokerData['token']!,
                              type: "mile_stone_completed",
                              screen: "BrokerMissionScreen",
                              extraData: {"senderName": courierData!['name']},
                            );
                            print("DEBUG: Notification sent");
                          }
                          final courierName = courierData?['name'] ?? 'Courier';

                          await firestoreService.createNotification(
                            brokerID: milestone.brokerID!,
                            courierID: currentUser.uid,
                            emptyLegRequestID: widget.task.emptyLegRequestID.toString(),
                            sentBy: "Courier",
                            milestoneID: milestone.milestoneNodeID.toString(),
                            message: "Your Milestone is Completed by $courierName",

                          );

                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text('Mark as Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                    if (roleProvider.role != UserRole.courier) ...[
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: 10,
                top: 5,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
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

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: RichText(
        text: TextSpan(
          text: '$label ',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          children: [
            TextSpan(
              text: value.toString(),
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

// Method to complete the job
  Future<void> completeJob(BuildContext context, String brokerID, String emptyLegRequestID) async {
    final FirestoreService service = FirestoreService(context);

    //job completion notification
    final User currentUser = FirebaseAuth.instance.currentUser!;
    final brokerData = await NotificationService.getBrokerNameAndTokenById(widget.task.brokerId.toString());
    final courierData = await NotificationService.getCourierNameAndTokenById(currentUser.uid.toString());

    if (brokerData != null) {
      await NotificationService.sendNotification(
        title: "Job Completed",
        toToken: brokerData['token']!,
        type: "job_completed",
        screen: "BrokerMissionScreen",
        extraData: {"senderName": courierData!['name']},
      );
      print("DEBUG: Notification sent");
    }

    try {
      // Mark the job as completed
      await service.updateJobStatus(emptyLegRequestID, 'Completed');
      service.updateEmptyLegTableJobStatus(emptyLegRequestID, 'Completed');
      // Prepare notification message
      final User currentUser = FirebaseAuth.instance.currentUser!;
      final String email = currentUser.email ?? 'Unknown User';

      final String message = "Your Job has been completed by ${courierData?['name'] ?? 'Courier'}";

      // Create notification after job completion
      await service.createNotification(
        brokerID: brokerID,
        courierID: currentUser.uid,
        emptyLegRequestID: emptyLegRequestID,
        sentBy: "Courier",
        message: message,
      );
      // Ensure UI updates properly before showing dialog
      if (!context.mounted) return;
      // Show custom success dialog
      CustomDialog.showCustomDialog3(
        context,
        "Job Completed Successfully",
        onOkPressed: () async {
          // Close the current job completion dialog
          Navigator.of(context).pop();

          // Ensure context is still valid before showing rating dialog
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (context) => RatingDialog(task: widget.task,),
            );
          }
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
                      RatingDialog(task: widget.task,));
              });

              return SizedBox(); // Return empty widget until the dialog is triggered
            }
          },
        );
      },
    );
  }
}

