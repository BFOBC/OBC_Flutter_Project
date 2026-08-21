import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/CustomDialog.dart';
import 'package:flutter/material.dart';
import '../../res/custom_colors.dart';
import '../common/screens/DrawerScreen.dart';
import 'package:broker_flutter_pp/ui/courier/ViewJob.dart';
import 'package:broker_flutter_pp/ui/broker/mission/ViewMilestone.dart';

class ViewCourierMission extends StatefulWidget {
  final Task? data;
  const ViewCourierMission({Key? key, this.data}) : super(key: key);

  @override
  _ViewCourierMissionState createState() => _ViewCourierMissionState();
}

class _ViewCourierMissionState extends State<ViewCourierMission> {
  int _selectedIndex = 0;
  final List<bool> _selectedToggle = [true, false];
  final List<String> _toggleText = ["Submission", "Milestone"];

  void _onTogglePressed(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedToggle[index] = true;
      _selectedToggle[1 - index] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Job'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: ToggleButtons(
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
            ),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? const ViewJob()
                : ViewMilestone(
                    selectedTab: _toggleText[_selectedIndex],
                    task: widget.data ?? Task(),
                  ),
          ),
        ],
      ),
    );
  }
}
