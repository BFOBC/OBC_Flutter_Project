import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:broker_flutter_pp/ui/broker/viewmodels/TaskViewModel.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import '../broker/CircularRating.dart';
import 'ViewCourierMission.dart';

class CourierMissions extends StatefulWidget {
  const CourierMissions({super.key});

  @override
  _CourierMissionsState createState() => _CourierMissionsState();
}

class _CourierMissionsState extends State<CourierMissions> {
  int _selectedIndex = 0;
  final List<bool> _selectedToggle = [true, false, false];
  final List<String> _toggleText = ["In Progress", "Todo", "Pending","Completed"];
  final List<Color> _colorList = [
    Colors.orange, // In Progress
    Colors.red,    // todo
    Colors.lightGreen,    // Pending
    Colors.green,  // Completed
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);

    // Fetch jobs and milestones data from Firestore
    final jobsWithMilestones = await _fetchJobsWithMilestones();

    // Populate TaskViewModel with the fetched data
    for (var job in jobsWithMilestones) {
      taskViewModel.addTask(Task(
        brokerId: job['brokerId'] ?? 'N/A',
        flightNumber: job['flightNumber'] ?? 'Unknown',
        departureFrom: job['departureFrom'] ?? 'Unknown',
        arriveAt: job['arriveAt'] ?? 'Unknown',
        status: job['status'] ?? 'Unknown',
        rating: job['rating'] ?? 0,
        startDateTime: job['startDateTime'] ?? 'Unknown',
        endDateTime: job['endDateTime'] ?? 'Unknown',
        bid: job['bid'] ?? '0',
      ));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchJobsWithMilestones() async {
    try {
      final service = FirestoreService(context);
      return await service.getJobsWithMilestones();
    } catch (e) {
      debugPrint("Error in _fetchJobsWithMilestones: $e");
      return [];
    }
  }
  @override
  Widget build(BuildContext context) {
    final dataMap = <String, double>{
      "In Progress": 40,
      "Todo": 30,
      "Pending": 30,
      "Completed": 30,
    };

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              CircularRating(
                dataMap: dataMap,
                colorList: _colorList,
              ),

              const SizedBox(height: 20),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                    fillColor: _colorList[_selectedIndex],
                    color: Colors.black,
                    constraints: const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
                    children: _toggleText.map((text) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(text),
                    )).toList(),
                  ),
                ),
              ),

              const Divider(thickness: 1.0, color: Colors.grey),

              Consumer<TaskViewModel>(
                builder: (context, taskViewModel, child) {
                  List<Task> tasks = taskViewModel.getTasksByStatus(_getStatusForIndex(_selectedIndex));

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                                color: _colorList[_selectedIndex],
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
                                  _navigateToLegsAndMilestones(task);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _colorList[_selectedIndex],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  minimumSize: const Size(100, 40),
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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
        return 'Todo';
      case 2:
        return 'Pending';
      default:
        return 'Completed';
    }
  }

  void _navigateToLegsAndMilestones(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewCourierMission(data: task),
      ),
    );
  }
}
