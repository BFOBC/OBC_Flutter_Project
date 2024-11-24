import 'package:broker_flutter_pp/ui/common/models/Visa.dart';
import 'package:flutter/material.dart';

/*class Visa {
  final String? country;
  final String? countryFlagUrl;
  final String? visaExpiryDate;
  final String? visaIssueDate;

  Visa({
     this.country,
     this.countryFlagUrl,
     this.visaExpiryDate,
     this.visaIssueDate,
  });
}*/

class Visas extends StatelessWidget {
  final List<Visa> visas;

  const Visas({
    super.key,
    required this.visas,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visa Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...visas.map((visa) => Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _buildInfoCard(visa),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Visa visa) {
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
            'Country: ${visa.countryName}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 5),
/*          Text(
            'Flag URL: ${visa.countryFlagUrl}', // Replace with actual flag widget if needed
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),*/
          const SizedBox(height: 5),
          Text(
            'Visa Expiry Date: ${visa.expiryDate}',
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Visa Issue Date: ${visa.expiryDate}',
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
}
