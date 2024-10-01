import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  final String title;
  const NotificationsScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "This is Notification Screen",
            style: TextStyle(fontSize: 24),
          ),          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
