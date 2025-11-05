import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../courier/models/CourierProfileData.dart';

class BasicInfo extends StatelessWidget {
  final CourierProfileData courierProfileData;

  const BasicInfo({super.key, required this.courierProfileData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildInfoCard('Name', _safeValue(courierProfileData.name)),
          const SizedBox(height: 10),
          _buildInfoCard('Email', _safeValue(courierProfileData.email)),
          const SizedBox(height: 10),
          _buildInfoCard('Phone', safeContact(courierProfileData.countryCode, courierProfileData.phoneNumber)),
          const SizedBox(height: 10),
          _buildInfoCard('Owned Car', _boolToYesNo(courierProfileData.hasCar.toString())),
          const SizedBox(height: 10),
          _buildInfoCard('Has Driving Licence', _boolToYesNo(courierProfileData.hasDrivingLicence.toString())),
          const SizedBox(height: 10),
          _buildInfoCard('Willing to do First Mile', _boolToYesNo(courierProfileData.willingToDoFirstLastMile.toString())),
          const SizedBox(height: 10),
          // Add more fields if needed
        ],
      ),
    );

  }

// 👇 Helper method to handle null/empty values
  String _safeValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'N/A';
    }
    return value;
  }
  String safeContact(String? code, String? number) {
    if ((code == null || code.trim().isEmpty) &&
        (number == null || number.trim().isEmpty)) {
      return 'N/A';
    }
    return '${code ?? ''}${number ?? ''}';
  }

  String _boolToYesNo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'No';
    }

    final lower = value.toLowerCase();
    if (lower == 'true') {
      return 'Yes';
    } else {
      return 'No';
    }
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

          // 👉 Value + Copy icon (for Phone or Email only)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
              ),
              if (label.toLowerCase() == 'phone' || label.toLowerCase() == 'email') ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    Fluttertoast.showToast(
                      msg: "$label copied!",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.black87,
                      textColor: Colors.white,
                      fontSize: 14.0,
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
