import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/courier/TaskDetailScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../res/custom_colors.dart';
import 'ViewJob.dart';
import 'CompleteMilestone.dart';

class ViewCourierMission extends StatefulWidget {
  final Task? task; // Replace YourDataType with the actual type of your model object
  final String selectedTab;

  ViewCourierMission({Key? key, this.task, required this.selectedTab}) : super(key: key);

  @override
  _ViewCourierMissionState createState() => _ViewCourierMissionState();
}

class _ViewCourierMissionState extends State<ViewCourierMission> {
  int _selectedIndex = 0; // Selected toggle index (0 for Empty Leg, 1 for Milestone)
  final List<bool> _selectedToggle = [true, false]; // Default is Empty Leg selected
  final List<String> _toggleText = ["Submission", "Milestone"];

  void _onTogglePressed(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedToggle[index] = true;
      _selectedToggle[1 - index] = false; // Toggle between the two options
    });
  }

  // Function to show the dialog
  void _showStartJobDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Do you want to start the job?'),
          actions: [
            // "Yes" Button
            TextButton(
              onPressed: () {
                // Update the job status in Firestore
                FirestoreService service = FirestoreService(context);
                service.updateJobStatus(widget.task!.emptyLegRequestID.toString(), "In Progress");
                String taskID=widget.task!.emptyLegRequestID!;
                final User currentUser = FirebaseAuth.instance.currentUser!;
                String email=currentUser.email!;
                service.createNotification(
                  brokerID: widget.task!.brokerId!,
                  courierID: currentUser.uid,
                  emptyLegRequestID: widget.task!.emptyLegRequestID!,
                  sentBy: "Courier",
                  message: "Your  Job $taskID is started by $email");

                // Show Snackbar with "Job started!" message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job started!'),
                  ),
                );

                // Handle the "Yes" action
                debugPrint("Job started!");

                // Navigate back to the previous screen
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
              child: const Text('Yes'),
            ),
            // "No" Button
            TextButton(
              onPressed: () {
                // Handle the "No" action
                debugPrint("Job not started.");
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Job'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ToggleButtons(
                      isSelected: _selectedToggle,
                      onPressed: _onTogglePressed,
                      borderRadius: BorderRadius.circular(10),
                      selectedBorderColor: Colors.grey,
                      selectedColor: Colors.white,
                      fillColor: Palette.primaryColor,
                      color: Colors.black,
                      constraints: const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
                      children: _toggleText.map((text) => Text(text)).toList(),
                    ),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _selectedIndex == 0
                    ? TaskDetailScreen(task: widget.task!) // Pass Task data to PlaceNewJob
                    : CompleteMilestone(selectedTab: widget.selectedTab,task: widget.task!,), // Pass Task data to AddNewMilestone
              ),
            ],
          ),
          // Only show FloatingActionButton if selectedTab is "Todo" or "Pending"
          if (widget.selectedTab == "Todo" || widget.selectedTab == "Pending")
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  // Show the Start Job dialog when the button is clicked
                  _showStartJobDialog();
                },
                backgroundColor: Palette.primaryColor,
                child: const Icon(
                  Icons.directions, // Replace with any icon of your choice
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
