import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final String title;

  const Home({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/google_logo.png', width: 100, height: 100),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
