import 'package:flutter/material.dart';

import '../../courier/models/CourierProfileData.dart';

class BasicInfo extends StatelessWidget {
  final CourierProfileData courierProfileData;

  const BasicInfo({super.key, required this.courierProfileData});

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
           SizedBox(height: 20),
          _buildInfoCard('Name', courierProfileData.name.toString()),
           SizedBox(height: 10),
          _buildInfoCard('Email', courierProfileData.email.toString()),
           SizedBox(height: 10),
          _buildInfoCard('Phone', courierProfileData.phoneNumber.toString()),
           SizedBox(height: 10),
          _buildInfoCard('Address',courierProfileData.address.toString()),
           SizedBox(height: 10),
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
