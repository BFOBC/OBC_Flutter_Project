import 'package:flutter/material.dart';

import '../common/models/CourierProfileData.dart';
import '../common/models/Passport.dart';


class Passports extends StatelessWidget {
  final List<Passport> passports;

  const Passports({
    super.key,
    required this.passports,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Passport Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...passports.map((passport) => Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _buildInfoCard(passport),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Passport passport) {
    return Container(
      width: double.infinity, // Make the card take the full width
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Name: ${passport.countryName}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          Text(
            'Passport Number: ${passport.passportNumber}',
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
          Text(
            'Issue Date: ${passport.issueDate}',
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
          Text(
            'Expiry Date: ${passport.expiryDate}',
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
}
