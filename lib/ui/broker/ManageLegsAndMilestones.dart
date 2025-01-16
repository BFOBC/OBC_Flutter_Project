import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../res/custom_colors.dart';
import 'PlaceNewJob.dart'; // Import the Add New Empty Leg screen
import 'AddNewMilestone.dart'; // Import the Add New Milestone screen

class ManageLegsAndMilestones extends StatefulWidget {
  final Task? data; // Replace YourDataType with the actual type of your model object
  String courierKey;
  String brokerKey;

  ManageLegsAndMilestones({
    super.key,
    this.data,
    required this.courierKey,
    required this.brokerKey,
  });

  @override
  _ManageLegsAndMilestonesState createState() =>
      _ManageLegsAndMilestonesState();
}

class _ManageLegsAndMilestonesState extends State<ManageLegsAndMilestones> {
  int _selectedIndex = 0; // Selected toggle index (0 for Empty Leg, 1 for Milestone)
  final List<bool> _selectedToggle = [
    true,
    false
  ]; // Default is Empty Leg selected
  final List<String> _toggleText = ["Milestone", "Submission"];
  late List<String> milestoneNodeID= [];
  Task? savedTask; // To store the saved task

  bool isValid = false;

  void _onTogglePressed(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedToggle[index] = true;
      _selectedToggle[1 - index] = false; // Toggle between the two options
    });
  }

  void _handleSave(Task task) {
    setState(() {
      savedTask = task;
    });
    // You can handle further logic here (e.g., API calls)
    print('Saved Task: ${task.startDateTime}, ${task.endDateTime}');
  }

  void _placeJob() {
    if (milestoneNodeID.isEmpty) {
      // Delayed execution to ensure dialog appears after the current frame is drawn
      print("milestoneNodeID.isEmpty");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showErrorDialog(context, "Please add a milestone first");
      });
      return; // Return early without sending the request
    }
    if (savedTask == null) {
      print("savedTask.isEmpty");
        // Delayed execution to ensure dialog appears after the current frame is drawn
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showErrorDialog(context, "Please add submission details");
        });
        return; // Return early without sending the request
    }
    sendEmptyLegRequest(context);
  }
  void _navigateToDrawerPage() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushNamed('/DrawerScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place New Job'),
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
                      constraints: const BoxConstraints(
                          minHeight: 40.0, minWidth: 120.0),
                      children: _toggleText.map((text) => Text(text)).toList(),
                    ),
                    // Removed SizedBox here to remove the extra margin
                  ],
                ),
              ),
              Expanded(
                child: _selectedIndex == 1
                    ? PlaceNewJob(
                  data: widget.data,
                  onSave: (savedData) {
                    // Handle the saved data from PlaceNewJob
                    print("Saved Data: $savedData");
                    // Add any additional logic for handling the saved data here
                    _handleSave(savedData); // Call the parent method to process the saved data
                  },
                )
                    : AddNewMilestone(
                  brokerKey: widget.brokerKey,
                  courierKey: widget.courierKey,
                  data: widget.data,
                  onMilestoneSaved: (nodeID) {
                    // Handle the milestone node ID from AddNewMilestone
                    print("Milestone saved with ID: $nodeID");
                    milestoneNodeID = nodeID;
                    // Add any additional logic here, such as updating the state
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        _placeJob();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.secondaryColor,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text('Request the Job'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

    );
  }

  Future<void> showErrorDialog(BuildContext context, String message) async {
    // Ensure the context is still valid before showing the dialog
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
  Future<void> sendEmptyLegRequest(BuildContext context) async {
    FirestoreService firestoreService = FirestoreService(context);
    // Create a new EmptyLegRequest with nodeID initially null

    EmptyLegRequest newRequest = EmptyLegRequest(
      brokerID: widget.brokerKey,
      courierID: widget.courierKey,
      emptyLegRequestID: null,
      // Will be updated when saving
      requestDateTime: DateTime.now().toIso8601String(),
      status: 'pending',
      milestoneNodeIDs: milestoneNodeID, // Now using a list
      startTimeDate: savedTask!.startDateTime!,
      endTimeDate: savedTask!.endDateTime!,
      departureLocation: savedTask!.departureFrom!,
      arrivalLocation: savedTask!.arriveAt!,
      bid: savedTask!.bid!,

    );

    // Save the request to Firestore
    await firestoreService.saveEmptyLegRequest(newRequest);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 10),
              const Text('Job request sent successfully'),
            ],
          ),
          actions: [
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _navigateToDrawerPage(); // Navigate to the Drawer page
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Future.delayed(const Duration(seconds: 10), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _navigateToDrawerPage();
      }
    });
  }
}
