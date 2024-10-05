import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/broker/data/BrokerProfileData.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/broker/BrokerProfileScreen.dart'; // Import the BrokerProfileScreen
import 'package:broker_flutter_pp/ui/courier/models/CourierProfileData.dart';
import 'package:provider/provider.dart';

import '../../courier/CourierProfile.dart';
import '../../courier/models/Passport.dart';
import '../../courier/models/Visa.dart';
import '../utils/RoleProvider.dart';

class CustomDrawerHeader extends StatelessWidget {
  const CustomDrawerHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a Profile object
    final brokerProfile = BrokerProfileData(
      id: 'OBC001',
      name: 'John Doe',
      website: 'www.johndoe.com',
      country: 'USA',
      license: ['XYZ-1234', 'ABC-5678', 'DEF-9012'],  // List of licenses
      email: "broker@gmail.com",
      paymentTerms: "hehe"
    );
    final courierProfile = CourierProfileData(
      id: 'OBC001',
      name: 'John Doe',
      website: 'www.johndoe.com',
      country: 'USA',
      license: ['XYZ-1234', 'ABC-5678', 'DEF-9012'],  // List of licenses
      email: "courier@gmail.com",
      paymentTerms: "hehe"
    );
    List<Visa> visas = [
      Visa(countryName: 'USA', expiryDate: '2025-12-31'),
      Visa(countryName: 'Canada', expiryDate: '2026-01-15'),
    ];

    List<Passport> passports = [
      Passport(countryName: 'Pakistan', expiryDate: '2030-05-20'),
      Passport(countryName: 'UAE', expiryDate: '2028-09-12'),
    ];
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ), // Update the color as needed
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
                    if (roleProvider.role == UserRole.broker) {
                      // Navigate to BrokerProfileScreen when the avatar is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  BrokerProfileScreen(profile: brokerProfile,)),
                      );
                    } else if (roleProvider.role == UserRole.courier) {
                      // Navigate to CourierProfile when the avatar is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CourierProfile(
                          courierProfile:courierProfile,
                          visas: visas,
                          passports: passports,
                        ),),
                      );
                    }

                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 25,
                    backgroundImage: AssetImage('assets/avatar.png'), // Replace with your image asset
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'OBC001',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Adjust font size to fit well
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: CustomSwitch(
              value: true,
              onChanged: (value) {
                print('Switch value: $value');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CustomSwitchState createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  void _toggleSwitch() {
    setState(() {
      _value = !_value;
    });
    widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleSwitch,
          child: Container(
            width: 50.0,
            height: 30.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: _value ? Colors.green : Colors.grey,
            ),
            child: Row(
              mainAxisAlignment: _value ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Container(
                  width: 25.0,
                  height: 25.0,
                  margin: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4), // Space between the toggle and the text
        Text(
          _value ? 'Online' : 'Offline',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
