
import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CourierNotificationsscreen extends StatefulWidget {
  const CourierNotificationsscreen({super.key});

  @override
  _CourierNotificationsScreenState createState() => _CourierNotificationsScreenState();
}

class _CourierNotificationsScreenState extends State<CourierNotificationsscreen> {
  List<Map<String, dynamic>> notifications = [];
  String? _removedNotification;
  int? _removedIndex;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  // Fetch notifications using FirestoreService
  Future<void> fetchNotifications() async {
    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      String role = roleProvider.role == UserRole.broker ? "Broker" : "Courier";

      List<Map<String, dynamic>> fetchedNotifications = await FirestoreService(context).readNotifications(role);
      setState(() {
        notifications = fetchedNotifications;
      });
    } catch (e) {
      print('Error fetching notifications: $e');
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
                  notifications.removeAt(index);  // Remove the notification from the list
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
        child: ListView.builder(
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
              onDismissed: (direction) {
                // Show confirmation dialog when swiped
                showDeleteConfirmationDialog(notification['notificationID'], index);
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
