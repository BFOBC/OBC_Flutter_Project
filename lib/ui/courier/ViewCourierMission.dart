import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:flutter/material.dart';
import '../../res/custom_colors.dart';
import 'ViewJob.dart';
import 'ViewMilestone.dart';

class ViewCourierMission extends StatefulWidget {
  final Task? task; // Replace YourDataType with the actual type of your model object
  ViewCourierMission({super.key, this.task});

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
                    ? ViewMilestone(task: widget.task!) // Pass Task data to PlaceNewJob
                    : ViewMilestone(task: widget.task!), // Pass Task data to AddNewMilestone
              ),
            ],
          ),
        ],
      ),
    );
  }
}
