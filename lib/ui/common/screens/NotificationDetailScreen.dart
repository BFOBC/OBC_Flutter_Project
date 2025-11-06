import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';

class NotificationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late String role;
  late String cardTitle;

  @override
  void initState() {
    super.initState();

    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    role = roleProvider.role == UserRole.broker ? "Broker" : "Courier";

    // 🔹 If Broker logged in → show "Courier Detail" on card
    // 🔹 If Courier logged in → show "Broker Detail" on card
    cardTitle = role == "Broker" ? "Courier" : "Broker";
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white), // 🔹 back arrow white
        title: const Text(
          "Notification Detail",
          style: TextStyle(
            color: Colors.white, // 🔹 title white
            fontWeight: FontWeight.normal,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  height: 260, // 🔹 fixed height for consistent card size
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔹 Dynamic card title here
                      Text(
                        cardTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Text(
                          notification['message'] ?? 'No message content available',
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                          overflow: TextOverflow.fade,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Sent By: ${notification['sentBy'] ?? 'N/A'}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Date: ${_formatDate(notification['currentDateTime'])}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
