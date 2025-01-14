import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/AuthUtils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:broker_flutter_pp/ui/common/viewmodels/TaskViewModel.dart';
import 'ManageLegsAndMilestones.dart';
import 'CircularRating.dart'; // Assuming you have this class imported

class Brokermissions extends StatefulWidget {
  const Brokermissions({super.key});

  @override
  _MyMissionsState createState() => _MyMissionsState();
}

class _MyMissionsState extends State<Brokermissions> {
  int _selectedIndex = 0;
  final List<bool> _selectedToggle = [true, false, false];
  final List<String> _toggleText = ["In Progress", "Completed", "Todo"];

  // Define the color list to match chart segments, tabs, and vertical bars
  final List<Color> _colorList = [
    Colors.orange,   // In Progress
    Colors.green,  // Completed
    Colors.red,   // Todo
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);

    taskViewModel.addTask(Task(
      brokerId: '1',
      flightNumber: 'AB123',
      departureFrom: 'City A',
      arriveAt: 'City B',
      status: 'In Progress',
      rating: 3,
      startDateTime: "21-9-2024",
      endDateTime: "30-9-2024",
      bid: "3000",
    ));
    taskViewModel.addTask(Task(
      brokerId: '2',
      flightNumber: 'CD456',
      departureFrom: 'City C',
      arriveAt: 'City D',
      status: 'Completed',
      rating: 2,
      startDateTime: "21-9-2024",
      endDateTime: "30-9-2024",
      bid: "3000",
    ));
    taskViewModel.addTask(Task(
      brokerId: '3',
      flightNumber: 'EF789',
      departureFrom: 'City E',
      arriveAt: 'City F',
      status: 'Todo',
      rating: 3,
      startDateTime: "21-9-2024",
      endDateTime: "30-9-2024",
      bid: "3000",
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dataMap = <String, double>{
      "In Progress": 40,
      "Completed": 30,
      "Todo": 30,
    };

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Circular Rating at the top center
              CircularRating(
                dataMap: dataMap,
                colorList: _colorList,  // Use the color list for the chart
              ),

              const SizedBox(height: 20),

              // Scrollable Toggle buttons with margins from start and end
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),  // Margin on both sides
                  child: ToggleButtons(
                    isSelected: _selectedToggle,
                    onPressed: (int index) {
                      setState(() {
                        _selectedIndex = index;
                        for (int i = 0; i < _selectedToggle.length; i++) {
                          _selectedToggle[i] = i == index;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    selectedBorderColor: Colors.grey,
                    selectedColor: Colors.white,
                    fillColor: _colorList[_selectedIndex],  // Use matching color for the selected tab
                    color: Colors.black,
                    constraints: const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
                    children: _toggleText.map((text) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0), // Add padding to each button
                      child: Text(text),
                    )).toList(),
                  ),
                ),
              ),

              const Divider(thickness: 1.0, color: Colors.grey),

              // Task List
              Consumer<TaskViewModel>(
                builder: (context, taskViewModel, child) {
                  List<Task> tasks = taskViewModel.getTasksByStatus(_getStatusForIndex(_selectedIndex));

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // Prevent list from scrolling independently
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 80,
                                color: _colorList[_selectedIndex],  // Vertical bar color matches the tab and chart
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Broker ID: ${task.brokerId}'),
                                    Text('Departure: ${task.departureFrom}'),
                                    Text('Arrive: ${task.arriveAt}'),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _navigateToLegsAndMilestones(task); // Navigate and pass task details
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _colorList[_selectedIndex],  // Button color matches the selected tab
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  // Set minimum height and width
                                  minimumSize: const Size(100, 40),  // Adjust this to reduce button size (width, height)
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),  // Control padding inside the button
                                ),
                                child: const Text(
                                  'View Details',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),

                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusForIndex(int index) {
    switch (index) {
      case 0:
        return 'In Progress';
      case 1:
        return 'Completed';
      default:
        return 'Todo';
    }
  }

  void _navigateToLegsAndMilestones(Task task) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageLegsAndMilestones(brokerKey:  AuthUtils.getCurrentUserId2().toString(),courierKey: "",data: task),
      ),
    );
  }
}
