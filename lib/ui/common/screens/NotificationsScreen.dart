
import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/screens/NotificationDetailScreen.dart';
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
      isLoading = true;
    });

    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      String selectedRole =
      roleProvider.role == UserRole.broker ? "Broker" : "Courier";
      String oppositeRole = selectedRole == 'Broker' ? 'Courier' : 'Broker';

      List<Map<String, dynamic>> fetchedNotifications =
      await FirestoreService(context).readNotifications(selectedRole);

      // 🔹 Filter only notifications sent by the opposite role
      List<Map<String, dynamic>> filteredNotifications = fetchedNotifications
          .where((n) => n['sentBy'] == oppositeRole)
          .toList();

      FirestoreService service = FirestoreService(context);

      // ✅ Step 1: Collect unique IDs
      Set<String> brokerIDs = {};
      Set<String> courierIDs = {};

      for (var n in filteredNotifications) {
        if (n['sentBy'] == 'Broker' && n['brokerID'] != null) {
          brokerIDs.add(n['brokerID']);
        } else if (n['sentBy'] == 'Courier' && n['courierID'] != null) {
          courierIDs.add(n['courierID']);
        }
      }

      // ✅ Step 2: Fetch names in parallel
      Map<String, String> brokerNames = {};
      Map<String, String> courierNames = {};

      await Future.wait([
        ...brokerIDs.map((id) async {
          brokerNames[id] = await service.getBrokerName(id);
        }),
        ...courierIDs.map((id) async {
          courierNames[id] = await service.getCourierName(id);
        }),
      ]);

      // ✅ Step 3: Replace names + job ID in notifications
      for (var n in filteredNotifications) {
        String name = '';
        if (n['sentBy'] == 'Broker') {
          name = brokerNames[n['brokerID']] ?? 'Unknown Broker';
        } else if (n['sentBy'] == 'Courier') {
          name = courierNames[n['courierID']] ?? 'Unknown Courier';
        }

        // 🆕 Get readable job ID
        final jobID = n['emptyLegRequestID'] ?? '';
        final readableJobID = getReadableJobID(jobID);

        // 🆕 Add to message
        n['message'] = "Your job $readableJobID is started by $name";
      }

      setState(() {
        notifications = filteredNotifications;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🧩 Helper function to make job IDs readable
  String getReadableJobID(String firestoreID) {
    if (firestoreID.isEmpty) return "number-UNKNOWN";
    final shortPart = firestoreID.length > 6
        ? firestoreID.substring(firestoreID.length - 6).toUpperCase()
        : firestoreID.toUpperCase();
    return "number-$shortPart";
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
          automaticallyImplyLeading: false, // 🔹 removes back button
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
                  subtitle: Text('Received: ${_formatDate(notification['currentDateTime'])}'),
                  leading: const Icon(
                    Icons.notifications,
                    color: Colors.blueAccent,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationDetailScreen(notification: notification),
                      ),
                    );
                  },

                ),
              ),
            );
          },
        ),
      ),
    );
  }
  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return '${_monthName(dateTime.month)} ${dateTime.day}, ${dateTime.year} – '
          '${_formatHour(dateTime.hour)}:${_formatMinute(dateTime.minute)} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
    } catch (e) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  String _formatHour(int hour) {
    final h = hour % 12;
    return (h == 0 ? 12 : h).toString().padLeft(2, '0');
  }

  String _formatMinute(int minute) {
    return minute.toString().padLeft(2, '0');
  }

}
