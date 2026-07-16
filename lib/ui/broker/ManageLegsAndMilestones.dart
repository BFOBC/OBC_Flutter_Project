import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/CustomDialog.dart';
import 'package:flutter/material.dart';
import '../../res/custom_colors.dart';
import '../common/screens/DrawerScreen.dart';
import 'PlaceNewJob.dart';  // Import the Add New Empty Leg screen
import 'AddNewMilestone.dart';      // Import the Add New Milestone screen

class ManageLegsAndMilestones extends StatefulWidget {
  final Task? data; // Replace YourDataType with the actual type of your data object
  const ManageLegsAndMilestones({Key? key, this.data}) : super(key: key);

  @override
  _ManageLegsAndMilestonesState createState() => _ManageLegsAndMilestonesState();
}

class _ManageLegsAndMilestonesState extends State<ManageLegsAndMilestones> {
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

  void _placeJob() {
    bool isValid = false;

    // Check validation based on the selected index
    if (_selectedIndex == 0) {
      // Validate PlaceNewJob screen
      isValid = (context.findAncestorStateOfType<PlaceNewJobState>()?.validate() ?? false);
    } else {
      // Validate AddNewMilestone screen
      // isValid = (context.findAncestorStateOfType<_AddNewMilestoneScreenState>()?.validate() ?? false);
    }

    if (!isValid) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Validations'),
            content: Text(
              _selectedIndex == 0
                  ? 'Please input submission details'
                  : 'Please input milestone details',
            ),
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
    } else {
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

      Future.delayed(const Duration(seconds: 5), () {
        if (Navigator.canPop(context)) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          _navigateToDrawerPage();
        }
      });
    }
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
                    ? PlaceNewJob(data: widget.data) // Pass Task data to PlaceNewJob
                    : AddNewMilestone(data: widget.data), // Pass Task data to AddNewMilestone
              ),
            ],
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    _placeJob();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primaryColor,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text('Request the Job'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
