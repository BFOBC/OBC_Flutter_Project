import 'package:flutter/material.dart';

class BrokerBasicInfo extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String website;
  final String company;

  const BrokerBasicInfo({
    Key? key,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.website,
    required this.company,
  }) : super(key: key);

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
          _buildInfoCard('Company Name', company),
          const SizedBox(height: 10),
          _buildInfoCard('Email', email),
          const SizedBox(height: 10),
          _buildInfoCard('Phone', phone),
          const SizedBox(height: 10),
          _buildInfoCard('Address', address),
          const SizedBox(height: 10),
          _buildInfoCard('Website', website),
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
