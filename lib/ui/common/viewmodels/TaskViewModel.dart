import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:flutter/foundation.dart';


class TaskViewModel extends ChangeNotifier {
  // List to store all tasks
  final List<Task> _tasks = [];
  final List<Milestone> _milestoneList = [];

  List<Task> get tasks => _tasks;
  List<Milestone> get milestoneList => _milestoneList;

  // Method to add a task
  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners(); // Notifies the UI when model changes
  }
  void addMilestone(Milestone milestone) {
    _milestoneList.add(milestone);
    notifyListeners(); // Notifies the UI when model changes
  }
  void clearTasks() {
    _tasks.clear();
    notifyListeners();  // Add this to notify UI after clearing the tasks
  }

  // Method to filter tasks based on status (In Progress, Completed, Todo)
  List<Task> getTasksByStatus(String status) {
    // Normalize the status to ignore case and spaces
    String normalizedStatus = status.replaceAll(' ', '').toLowerCase();

    // Filter tasks based on the normalized status
    final filteredTasks = _tasks.where((task) {
      // Normalize each task's status similarly
      String normalizedTaskStatus = task.status!.replaceAll(' ', '').toLowerCase();
      return normalizedTaskStatus == normalizedStatus;
    }).toList();

    debugPrint("Filtered tasks for status '$status': ${filteredTasks.length}");
    return filteredTasks;
  }

}
