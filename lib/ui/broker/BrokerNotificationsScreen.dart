import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../admin/User.dart';

class BrokerNotificationsScreen extends StatefulWidget {
  const BrokerNotificationsScreen({super.key});

  @override
  _BrokerNotificationsScreenState createState() => _BrokerNotificationsScreenState();
}

class _BrokerNotificationsScreenState extends State<BrokerNotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      String selectedRole = roleProvider.role == UserRole.broker ? "Broker" : "Courier";

      print('🔵 Selected Role: $selectedRole');

      // Fetch notifications for the current user's ID
      List<Map<String, dynamic>> fetchedNotifications =
      await FirestoreService(context).readNotifications(selectedRole);

      print('📥 Total fetched notifications: ${fetchedNotifications.length}');

      // Log each notification's sentBy field
      for (var i = 0; i < fetchedNotifications.length; i++) {
        final notif = fetchedNotifications[i];
        print('🔍 Notification ${i + 1} - sentBy: ${notif['sentBy']} | message: ${notif['message']}');
      }

      // Filter to show only the notifications sent by the OPPOSITE role
      String oppositeRole = selectedRole == 'Broker' ? 'Courier' : 'Broker';
      print('🟣 Filtering notifications where sentBy == $oppositeRole');

      List<Map<String, dynamic>> filteredNotifications = fetchedNotifications.where((notification) {
        return notification['sentBy'] == oppositeRole;
      }).toList();

      print('✅ Filtered notifications count: ${filteredNotifications.length}');

      setState(() {
        notifications = filteredNotifications;
      });
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      setState(() {});
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
                // Don't remove the item immediately; instead, show the confirmation dialog
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
