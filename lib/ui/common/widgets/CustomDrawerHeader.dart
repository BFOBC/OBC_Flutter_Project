import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/broker/data/BrokerProfileData.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/broker/BrokerProfileScreen.dart'; // Import the BrokerProfileScreen
import 'package:broker_flutter_pp/ui/courier/models/CourierProfileData.dart';
import 'package:provider/provider.dart';

import '../../courier/CourierProfile.dart';
import '../utils/RoleProvider.dart';

class CustomDrawerHeader extends StatelessWidget {
  const CustomDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final brokerProfile = Provider.of<RoleProvider>(context).brokerProfile;
    final courierProfile = Provider.of<RoleProvider>(context).courierProfile;

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
                        MaterialPageRoute(builder: (context) =>  BrokerProfileScreen(brokerProfile: brokerProfile,)),
                      );
                    } else if (roleProvider.role == UserRole.courier) {
                      // Navigate to CourierProfile when the avatar is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  CourierProfile(courierProfile: courierProfile, visas: [], passports: [],)),
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
    super.key,
    required this.value,
    required this.onChanged,
  });

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