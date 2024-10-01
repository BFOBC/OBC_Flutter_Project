import 'package:flutter/foundation.dart';

import '../data/Task.dart';

class TaskViewModel extends ChangeNotifier {
  // List to store all tasks
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  // Method to add a task
  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners(); // Notifies the UI when data changes
  }

  // Method to filter tasks based on status (In Progress, Completed, Todo)
  List<Task> getTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).toList();
  }
}
