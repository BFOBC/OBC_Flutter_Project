import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/broker/mission/PlaceNewJob.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../res/custom_colors.dart';
import '../requestscreens/AddNewMilestone.dart'; // Import the Add New Milestone screen

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
    Task? task=Provider.of<RoleProvider>(context, listen: false).task;
    if(task==null){
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
    return WillPopScope(
      onWillPop: () async {
        // Aap yahan pe apna custom logic dal sakte hain
        print("Back press hua!");
        bool shouldLeave = await showExitConfirmationDialog(context);
        return shouldLeave; // agar true return hoga to back ho jaye ga
        dispose();
        // Agar back press ko allow karna hai to true return karein
        return true;
      },
      child: Scaffold(
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
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedIndex == 1
                      ? PlaceNewJob(
                    data: widget.data,
                    onSave: (savedData) {
                      print("Saved Data: $savedData");
                      _handleSave(savedData);
                    }, brokerKey: widget.brokerKey, courierKey: widget.courierKey,
                  )
                      : AddNewMilestone(
                    brokerKey: widget.brokerKey,
                    courierKey: widget.courierKey,
                    data: widget.data,
                    onMilestoneSaved: (nodeID) {
                      print("Milestone saved with ID: $nodeID");
                      milestoneNodeID = nodeID;
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
    // Clear milestone list from provider
    Provider.of<RoleProvider>(context, listen: false).clearMilestoneNodeIDS();
    Provider.of<RoleProvider>(context, listen: false).clearTask();
    FirestoreService firestoreService = FirestoreService(context);
    // Create a new EmptyLegRequest with nodeID initially null

    EmptyLegRequest newRequest = EmptyLegRequest(
      brokerID: widget.brokerKey,
      courierID: widget.courierKey,
      emptyLegRequestID: savedTask!.emptyLegRequestID!,
      // Will be updated when saving
      requestDateTime: DateTime.now().toIso8601String(),
      status: 'pending',
      milestoneNodeIDs: milestoneNodeID, // Now using a list
      startTimeDate: savedTask!.startDateTime!,
      endTimeDate: savedTask!.endDateTime!,
      departureLocation: savedTask!.departureFrom!,
      arrivalLocation: savedTask!.arriveAt!,
      bid: savedTask!.bid!,
      isCourierRated: 'false',
      isBrokerRated: 'false',
      courierCapacity: savedTask!.courierCapacity

    );
    newRequest.startTimeDate=convertToUTCFromStandardFormat(newRequest.startTimeDate.toString());
    newRequest.endTimeDate=convertToUTCFromStandardFormat(newRequest.endTimeDate.toString());
    // Save the request to Firestore
    print(newRequest.startTimeDate.toString());

    await firestoreService.saveEmptyLegRequest(newRequest,milestoneNodeID);


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
  @override
  void dispose() {
    // Clear milestone list from provider
    Provider.of<RoleProvider>(context, listen: false).clearMilestoneNodeIDS();
    Provider.of<RoleProvider>(context, listen: false).clearTask();
    print("Manage Leg dispose call ho rha ha");
    super.dispose();
  }
  Future<bool> showExitConfirmationDialog(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: const Text("If you go back, your changes will be removed."),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false); // don't leave
              },
            ),
            ElevatedButton(
              child: const Text("Yes"),
              onPressed: () {
                // Clear milestone list from provider
                Provider.of<RoleProvider>(context, listen: false).clearMilestoneNodeIDS();
                Provider.of<RoleProvider>(context, listen: false).clearTask();
                Navigator.of(context).pop(true); // allow back
              },
            ),
          ],
        );
      },
    );

    return result ?? false; // default to false if dialog dismissed
  }
}

