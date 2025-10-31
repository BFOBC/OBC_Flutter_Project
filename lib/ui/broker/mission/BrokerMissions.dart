import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/AuthUtils.dart';
import 'package:broker_flutter_pp/ui/courier/missions/ViewCourierMission.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:broker_flutter_pp/ui/common/viewmodels/TaskViewModel.dart';
import '../../common/models/Milestone.dart';
import 'ManageLegsAndMilestones.dart';
import '../CircularRating.dart'; // Assuming you have this class imported

class BrokerMissions extends StatefulWidget {
  const BrokerMissions({super.key});

  @override
  _BrokerMissionsState createState() => _BrokerMissionsState();
}

class _BrokerMissionsState extends State<BrokerMissions> {
  int _selectedIndex = 0;
  final List<bool> _selectedToggle = [true, false, false, false];
  final List<String> _toggleText = [
    "Pending",
    "Todo",
    "In Progress",
    "Completed"
  ];
  bool isLoading = true; // Track loading state
  // Define the color list to match chart segments, tabs, and vertical bars
  final List<Color> _colorList = [
    Colors.orange, // In Progress
    Colors.red, // Todo
    Colors.lightGreen, // Pending
    Colors.green, // Completed
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
/*    final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);

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
    ));*/

    final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);

    try {
      // Set loading to true while fetching data
      setState(() {
        isLoading = true;
      });

      // Fetch jobs and milestones data from Firestore
      final jobsWithMilestones = await _fetchJobsWithMilestones();
      debugPrint("Found Courier Mission $jobsWithMilestones");

      // Clear existing tasks before populating new ones
      taskViewModel.clearTasks();

      // Populate TaskViewModel with the fetched data
      for (var job in jobsWithMilestones) {
        debugPrint("Job: $job");
        taskViewModel.addTask(Task(
          brokerId: job['brokerID'] ?? 'N/A',
          flightNumber: job['flightNumber'] ?? 'Unknown',
          departureFrom: job['departureLocation'] ?? 'Unknown',
          arriveAt: job['arrivalLocation'] ?? 'Unknown',
          status: job['status'] ?? 'Unknown',
          rating: job['rating'] != null ? double.tryParse(
              job['rating'].toString()) ?? 0.0 : 0.0,
          startDateTime: job['startTimeDate'] ?? 'Unknown',
          endDateTime: job['endTimeDate'] ?? 'Unknown',
          bid: job['bid'] ?? 'N/A',
          title: job['milestones'] != null && job['milestones'].isNotEmpty
              ? job['milestones'][0]['title'] ?? 'N/A'
              : 'N/A',
          description: job['milestones'] != null && job['milestones'].isNotEmpty
              ? job['milestones'][0]['description'] ?? 'N/A'
              : 'N/A',
          mileStoneStatus: job['milestones'] != null &&
              job['milestones'].isNotEmpty
              ? job['milestones'][0]['status'] ?? 'N/A'
              : 'N/A',
          emptyLegRequestID: job['emptyLegRequestID'] ?? 'Unknown',
        ));
        // Add milestones to milestone list
        if (job['milestones'] != null && job['milestones'].isNotEmpty) {
          for (var milestone in job['milestones']) {
            taskViewModel.addMilestone(Milestone(
              milestoneNodeID: milestone['milestoneNodeID'] ?? 'Unknown',
              brokerID: milestone['brokerID'] ?? 'Unknown',
              milestoneEndDateTime: milestone['milestoneEndDateTime'] ??
                  'Unknown',
              description: milestone['description'] ?? 'N/A',
              courierID: milestone['courierID'] ?? 'Unknown',
              title: milestone['title'] ?? 'N/A',
              milestoneStartDateTime: milestone['milestoneStartDateTime'] ??
                  'Unknown',
              milestoneStatus: milestone['milestoneStatus'] ?? 'Unknown',
              emptyLegRequestID: milestone['emptyLegRequestID'] ?? 'Unknown',
            ));
          }
        }
      }
      debugPrint("Total Milestones");
      debugPrint(taskViewModel.milestoneList.length.toString());
    } catch (e) {
      debugPrint("Error in _loadTasks: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load tasks. Please try again.")),
        );
      }
    } finally {
      // Set loading to false when data has been fetched
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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

              // Circular Rating at the top center
              CircularRating(
                dataMap: dataMap,
                colorList: _colorList, // Use the color list for the chart
              ),

              const SizedBox(height: 20),

              // Scrollable Toggle buttons with margins from start and end
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  // Margin on both sides
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
                    // Use matching color for the selected tab
                    color: Colors.black,
                    constraints: const BoxConstraints(
                        minHeight: 40.0, minWidth: 120.0),
                    children: _toggleText.map((text) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          // Add padding to each button
                          child: Text(text),
                        )).toList(),
                  ),
                ),
              ),

              const Divider(thickness: 1.0, color: Colors.grey),

              // Task List
              Consumer<TaskViewModel>(
                builder: (context, taskViewModel, child) {
                  List<Task> tasks = taskViewModel.getTasksByStatus(
                      _getStatusForIndex(_selectedIndex));

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Prevent list from scrolling independently
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0,
                            horizontal: 4.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 80,
                                color: _colorList[_selectedIndex], // Vertical bar color matches the tab and chart
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Departure: ${task.departureFrom}'),
                                    Text('Arrive: ${task.arriveAt}'),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _navigateToLegsAndMilestones(
                                      task); // Navigate and pass task details
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _colorList[_selectedIndex],
                                  // Button color matches the selected tab
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  // Set minimum height and width
                                  minimumSize: const Size(100, 40),
                                  // Adjust this to reduce button size (width, height)
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 12.0), // Control padding inside the button
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
        return 'Pending';
      case 1:
        return 'Todo';
      case 2:
        return 'In Progress';
      default:
        return 'Completed';
    }
  }

  void _navigateToLegsAndMilestones(Task task) {

/*    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageLegsAndMilestones(brokerKey:  AuthUtils.getCurrentUserId2().toString(),courierKey: "",data: task),
      ),
    );
  }*/
    String selectedTab = _getStatusForIndex(_selectedIndex);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ViewCourierMission(task: task, selectedTab: selectedTab),
      ),
    ).then((_) {
      // Reload data when coming back
      _loadTasks();
    });
  }
}
