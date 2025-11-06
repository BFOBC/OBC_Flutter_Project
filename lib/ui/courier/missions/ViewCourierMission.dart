
import 'package:broker_flutter_pp/data/notification/NotificationService.dart';
import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:broker_flutter_pp/ui/common/widgets/RatingDialog.dart';
import 'package:broker_flutter_pp/ui/courier/missions/TaskDetailScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../res/custom_colors.dart';
import '../ViewJob.dart';
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

  bool _dialogShown = false; // ڈائیلاگ شو ہونے کا ٹریکر

  void _onTogglePressed(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedToggle[index] = true;
      _selectedToggle[1 - index] = false; // Toggle between the two options
    });
  }
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

// Check if the task is not rated (based on the role) and the selected tab is "Completed"
    bool shouldShowDialog = widget.selectedTab == "Completed" && !_dialogShown;

    if (roleProvider.role == UserRole.courier && widget.task?.isCourierRated == "false" && shouldShowDialog) {
      _dialogShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RatingDialog(task: widget.task!),
        );
      });
    } else if (roleProvider.role != UserRole.courier && widget.task?.isBrokerRated == "false" && shouldShowDialog) {
      _dialogShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RatingDialog(task: widget.task!),
        );
      });
    }


  }

  void _showStartJobDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: const [
              Icon(Icons.play_circle_fill, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Do you want to start the job?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            // "Yes" Button
            ElevatedButton.icon(
              onPressed: () async {
                FirestoreService service = FirestoreService(context);
                service.updateJobStatus(widget.task!.emptyLegRequestID.toString(), "In Progress");
                service.updateEmptyLegTableJobStatus(widget.task!.emptyLegRequestID.toString(), "In Progress");
                String taskID = widget.task!.emptyLegRequestID!;
                final User currentUser = FirebaseAuth.instance.currentUser!;
                String email = currentUser.email!;

                service.createNotification(
                  brokerID: widget.task!.brokerId!,
                  courierID: currentUser.uid,
                  emptyLegRequestID: widget.task!.emptyLegRequestID!,
                  sentBy: "Courier",
                  message: "Your Job is started by $email",
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job started!'),
                  ),
                );

                final brokerData = await NotificationService.getBrokerNameAndTokenById(widget.task!.brokerId.toString());
                final courierData = await NotificationService.getCourierNameAndTokenById(currentUser.uid.toString());
                print("Broker Data Job Started: $brokerData");
                print("Broker Token $brokerData['token']");
                if (brokerData != null) {
                  await NotificationService.sendNotification(
                    title: "Job Started",
                    toToken: brokerData['token']!,
                    type: "job_started",
                    screen: "BrokerMissionScreen",
                    extraData: {"senderName": courierData!['name']},
                  );
                  print("Job Started");
                }else{

                  print("Job Not Started");
                }

                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Yes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // "No" Button
            ElevatedButton.icon(
              onPressed: () {
                debugPrint("Job not started.");
                Navigator.of(context).pop(); // Close the dialog
              },
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('No'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    final bool isCourier = roleProvider.role == UserRole.courier;

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
                    : CompleteMilestone(selectedTab: widget.selectedTab, task: widget.task!), // Pass Task data to AddNewMilestone
              ),
            ],
          ),
          // Show FloatingActionButton only if:
          // - selectedTab is "Todo" or "Pending"
          // - user role is Courier
          if ((widget.selectedTab == "Todo" || widget.selectedTab == "Pending") && isCourier)
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
