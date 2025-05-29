import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/res/strings.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  String role = '';
  bool isLoading = true;  // To track the loading state

  @override
  void initState() {
    super.initState();
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    role = roleProvider.role == UserRole.broker ? "Broker" : "Courier";
    fetchNotifications();
  }

  // Fetch notifications using FirestoreService
  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;  // Show the progress bar while fetching data
    });

    try {
      // Get the current role from the RoleProvider
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      String role = roleProvider.role == UserRole.broker ? "Broker" : "Courier";


      print('Selected Role is');
      print(role);

      // Fetch all notifications from Firestore
      List<Map<String, dynamic>> fetchedNotifications = await FirestoreService(context).readNotifications(role);

      // Filter notifications based on the selected role
      List<Map<String, dynamic>> filteredNotifications = fetchedNotifications.where((notification) {
        return notification['sentBy'] == role;
      }).toList();

      setState(() {
        notifications = filteredNotifications;  // Update the state with the filtered notifications
        isLoading = false;  // Hide the progress bar after fetching data
      });
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        isLoading = false;  // Hide the progress bar if there's an error
      });
    }
  }

  // Show confirmation dialog when trying to delete a notification
  Future<void> showDeleteConfirmationDialog(String notificationID, int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Notification'),
          content: const Text('Are you sure you want to remove this notification?'),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog without deleting
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Delete the notification from Firestore
                await FirestoreService(context).deleteNotification(notificationID);
                setState(() {
                  notifications.removeAt(index);  // Remove the notification from the list after confirmation
                });
                Navigator.of(context).pop();  // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification deleted')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(),  // Show progress bar while loading
        )
            : notifications.isEmpty
            ? Center(
          child: Text(
            'No notifications available',  // Show this text if no notifications are found
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        )
            : ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];

            return Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              confirmDismiss: (direction) async {
                // Show the confirmation dialog instead of removing the item immediately
                await showDeleteConfirmationDialog(notification['notificationID'], index);
                return false; // Prevent the default swipe-to-dismiss behavior
              },
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  title: Text(notification['message']),
                  subtitle: Text('Received: ${notification['currentDateTime']}'),
                  leading: const Icon(
                    Icons.notifications,
                    color: Colors.blueAccent,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Handle notification click
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
