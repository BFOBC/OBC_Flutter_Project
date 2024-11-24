import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Hardcoded notifications
  List<String> notifications = [
    'Your account has been updated successfully.',
    'New message from the support team.',
    'Your password will expire in 3 days.',
    'A new version of the app is available.',
    'Reminder: Complete your profile.',
    'Payment for the premium plan is due soon.',
  ];

  // To store the removed notification in case of undo
  String? _removedNotification;
  int? _removedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0), // Customize height here
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.blueAccent], // Green to dark blue gradient
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
                setState(() {
                  _removedNotification = notifications[index];
                  _removedIndex = index;
                  notifications.removeAt(index);
                });

                // Show Snackbar with Undo action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Notification dismissed'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        if (_removedNotification != null && _removedIndex != null) {
                          setState(() {
                            notifications.insert(_removedIndex!, _removedNotification!);
                          });
                        }
                      },
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  title: Text(notification),
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
