import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/CustomDialog.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:broker_flutter_pp/ui/common/widgets/RatingDialog.dart';

class ViewMilestone extends StatefulWidget {
  final String selectedTab;
  final Task task;

  const ViewMilestone({Key? key, required this.selectedTab, required this.task}) : super(key: key);

  @override
  State<ViewMilestone> createState() => _ViewMilestoneState();
}

class _ViewMilestoneState extends State<ViewMilestone> {
  late Future<List<Milestone>> milestonesFuture;

  @override
  void initState() {
    super.initState();
    milestonesFuture = _fetchMilestones();
  }

  Future<List<Milestone>> _fetchMilestones() async {
    try {
      print('Fetching milestones for ID: ${widget.task.emptyLegRequestID}');
      final firestoreService = FirestoreService(context);
      final milestones = await firestoreService.getMilestonesByEmptyLegCourierID(widget.task.emptyLegRequestID!);
      print('Milestones fetched: ${milestones.length}');
      return milestones;
    } catch (e) {
      print('Error fetching milestones: $e');
      return [];
    }
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
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '🚫 No Milestones Found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final milestones = snapshot.data!;
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
                              color: milestone.milestoneStatus == "Completed"
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 60,
                            color: Colors.grey,
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
                            Text('Start: ${milestone.localStartDateTime ?? 'N/A'}'),
                            Text('End: ${milestone.localEndDateTime ?? 'N/A'}'),
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
                        child: const Text('View', style: TextStyle(color: Colors.white)),
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
      builder: (context) => AlertDialog(
        title: const Text("Milestone Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📌 Title: ${milestone.title}'),
            Text('📝 Description: ${milestone.description}'),
            Text('⏰ Start Time: ${milestone.localStartDateTime}'),
            Text('⏳ End Time: ${milestone.localEndDateTime}'),
            Text('📍 Status: ${milestone.milestoneStatus}'),
          ],
        ),
        actions: [
          if (widget.selectedTab == "In Progress" &&
              FirebaseAuth.instance.currentUser != null &&
              roleProvider.role == UserRole.courier &&
              milestone.milestoneStatus != "Completed")
            ElevatedButton(
              onPressed: () async {
                final firestoreService = FirestoreService(context);
                await firestoreService.updateMilestoneStatus(milestone.milestoneNodeID.toString(), "Completed");

                setState(() {
                  milestonesFuture = _fetchMilestones();
                });

                final currentUser = FirebaseAuth.instance.currentUser!;
                await firestoreService.createNotification(
                  brokerID: milestone.brokerID!,
                  courierID: currentUser.uid,
                  emptyLegRequestID: widget.task.emptyLegRequestID!,
                  sentBy: "Courier",
                  message: "Your Milestone is Completed by ${currentUser.email}",
                );

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Mark as Done"),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> completeJob(BuildContext context, String brokerID, String requestID) async {
    final service = FirestoreService(context);
    final currentUser = FirebaseAuth.instance.currentUser!;

    try {
      await service.updateJobStatus(requestID, 'Completed');
      await service.updateEmptyLegTableJobStatus(requestID, 'Completed');
      await service.createNotification(
        brokerID: brokerID,
        courierID: currentUser.uid,
        emptyLegRequestID: requestID,
        sentBy: "Courier",
        message: "Your Job has been completed by ${currentUser.email ?? "a user"}",
      );

      if (!context.mounted) return;

      CustomDialog.showCustomDialog3(
        context,
        "Job Completed Successfully",
        onOkPressed: () async {
          Navigator.of(context).pop();
          if (context.mounted) {
            await showDialog(context: context, builder: (_) => RatingDialog(task: widget.task));
          }
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to complete the job: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void showJobCompletionDialog(BuildContext context, Future<List<Milestone>> milestonesFuture) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<Milestone>>(
        future: milestonesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final milestones = snapshot.data ?? [];
          final pending = milestones.where((m) => m.milestoneStatus == 'Pending').toList();

          if (pending.isNotEmpty) {
            return AlertDialog(
              title: const Text('Job Completion Warning'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Some milestones are still pending:'),
                  const SizedBox(height: 10),
                  ...pending.map((m) => Text('• ${m.title}')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    await completeJob(context, widget.task.brokerId!, widget.task.emptyLegRequestID!);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Complete Anyway"),
                )
              ],
            );
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(context: context, builder: (_) => RatingDialog(task: widget.task));
            });
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
