
import 'package:broker_flutter_pp/data/notification/NotificationService.dart';
import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:broker_flutter_pp/ui/common/viewmodels/TaskViewModel.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import '../../broker/CircularRating.dart';
import 'ViewCourierMission.dart';

class CourierMissions extends StatefulWidget {
  const CourierMissions({super.key});

  @override
  _CourierMissionsState createState() => _CourierMissionsState();
}

class _CourierMissionsState extends State<CourierMissions> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final List<bool> _selectedToggle = [true, false, false, false];
  final List<String> _toggleText = ["Pending", "Todo", "In Progress", "Completed"];
  final List<Color> _colorList = [
    Colors.orange, // In Progress
    Colors.red,    // Todo
    Colors.lightGreen,    // Pending
    Colors.green,  // Completed
  ];
  Task selectedTask=new Task();
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    NotificationService.currentRoute = "CourierMissions";
    WidgetsBinding.instance.addObserver(this);
    _loadTasks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.currentRoute = null;
    super.dispose();
  }

  @override
  void didPopNext() {
    // Reload tasks when coming back to the screen
    _loadTasks();
  }

  Future<void> _loadTasks() async {
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
          rating: job['rating'] != null ? double.tryParse(job['rating'].toString()) ?? 0.0 : 0.0,
          startDateTime: job['startTimeDate'] ?? 'Unknown',
          endDateTime: job['endTimeDate'] ?? 'Unknown',
          bid: job['bid'] ?? 'N/A',
          title: job['milestones'] != null && job['milestones'].isNotEmpty
              ? job['milestones'][0]['title'] ?? 'N/A'
              : 'N/A',
          description: job['milestones'] != null && job['milestones'].isNotEmpty
              ? job['milestones'][0]['description'] ?? 'N/A'
              : 'N/A',
          mileStoneStatus: job['milestones'] != null && job['milestones'].isNotEmpty
              ? job['milestones'][0]['status'] ?? 'N/A'
              : 'N/A',
          emptyLegRequestID: job['emptyLegRequestID'] ?? 'Unknown',
          isCourierRated: job['isCourierRated'] ?? 'false',
          isBrokerRated: job['isBrokerRated'] ?? 'false'
        ));
        // Add milestones to milestone list
        if (job['milestones'] != null && job['milestones'].isNotEmpty) {
          for (var milestone in job['milestones']) {
            taskViewModel.addMilestone(Milestone(
              milestoneNodeID: milestone['milestoneNodeID'] ?? 'Unknown',
              brokerID: milestone['brokerID'] ?? 'Unknown',
              milestoneEndDateTime: milestone['milestoneEndDateTime'] ?? 'Unknown',
              description: milestone['description'] ?? 'N/A',
              courierID: milestone['courierID'] ?? 'Unknown',
              title: milestone['title'] ?? 'N/A',
              milestoneStartDateTime: milestone['milestoneStartDateTime'] ?? 'Unknown',
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
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              //pie chart
              CircularRating(dataMap: dataMap, colorList: _colorList),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
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
                    borderRadius: BorderRadius.circular(5),
                    selectedBorderColor: Colors.grey,
                    selectedColor: Colors.white,
                    fillColor: _colorList[_selectedIndex],
                    color: Colors.black,
                    constraints: const BoxConstraints(
                      minHeight: 40.0,  // Equal height for the tabs
                      minWidth: 80.0,   // Equal width for the tabs
                    ),
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

                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No Data Available',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

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
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Departure: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: '${task.departureFrom}', // Value remains normal
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Arrival: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: '${task.arriveAt}', // Value remains normal
                                          ),
                                        ],
                                      ),
                                    ),
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
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  minimumSize: const Size(40, 15),
                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                                ),
                                child: const Text(
                                  'View',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
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
      )
      ,
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
    String selectedTab = _getStatusForIndex(_selectedIndex);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewCourierMission(task: task, selectedTab: selectedTab),
      ),
    ).then((_) {
      // Reload data when coming back
      _loadTasks();
    });
  }
  Map<String, double> calculateStatusDistribution(List<String> statusList) {
    if (statusList.isEmpty) {
      return {
        "In Progress": 0,
        "To-Do": 0,
        "Pending": 0,
        "Completed": 0,
      };
    }

    // Count occurrences of each status
    Map<String, int> statusCount = {
      "In Progress": 0,
      "To-Do": 0,
      "Pending": 0,
      "Completed": 0,
    };

    for (var status in statusList) {
      if (statusCount.containsKey(status)) {
        statusCount[status] = statusCount[status]! + 1;
      }
    }

    // Convert counts to percentage
    int total = statusList.length;
    Map<String, double> dataMap = statusCount.map(
          (key, value) => MapEntry(key, (value / total) * 100),
    );

    return dataMap;
  }

}

