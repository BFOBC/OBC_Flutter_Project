import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BasicInfo extends StatelessWidget {
  final String name;

  BasicInfo({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildInfoCard('Name', name),
          const SizedBox(height: 10),
          _buildInfoCard('Email', 'johndoe@example.com'),
          const SizedBox(height: 10),
          _buildInfoCard('Phone', '+1234567890'),
          const SizedBox(height: 10),
          _buildInfoCard('Address', '123 Main Street'),
          const SizedBox(height: 10),
          _buildInfoCard('Occupation', 'Software Engineer'),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
}
