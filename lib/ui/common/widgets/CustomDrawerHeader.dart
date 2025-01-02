import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/broker/model/BrokerProfileData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/broker/BrokerProfileScreen.dart'; // Import the BrokerProfileScreen
import 'package:broker_flutter_pp/ui/courier/models/CourierProfileData.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

import '../../courier/CourierProfile.dart';
import '../utils/AuthUtils.dart';
import '../utils/RoleProvider.dart';

class CustomDrawerHeader extends StatelessWidget {
  CustomDrawerHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final brokerProfile = Provider.of<RoleProvider>(context).brokerProfile;
    final courierProfile = Provider.of<RoleProvider>(context).courierProfile;
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
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
                        MaterialPageRoute(builder: (context) =>  CourierProfile()));
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
            child: FutureBuilder<String?>(
              future: AuthUtils.getCurrentUserId(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Loading while fetching user ID
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Text('Error: ${snapshot.error ?? "No user ID found"}');
                }

                String? userId = snapshot.data;
                if (userId == null) {
                  return Text("No user logged in");
                }

                return SwitchWithOnlineStatus(userId: userId);
              },
            ),
          )
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

class SwitchWithOnlineStatus extends StatefulWidget {
  final String userId;

  SwitchWithOnlineStatus({required this.userId});

  @override
  State<SwitchWithOnlineStatus> createState() => _SwitchWithOnlineStatusState();
}

class _SwitchWithOnlineStatusState extends State<SwitchWithOnlineStatus> {
  String table = "";

  // Fetch user model from Firestore
  Future<bool> _fetchUserStatus(BuildContext context) async {
    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      if (roleProvider.role == UserRole.broker) {
        table = "broker";
      } else {
        table = "courier";
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(table)
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        // Assuming 'isOnline' is a boolean field in Firestore
        return userDoc['isOnline'] ?? false; // Default to false if 'isOnline' is not found
      } else {
        return false; // Default to false if user doesn't exist
      }
    } catch (e) {
      print('Error fetching user status: $e');
      return false; // Default to false in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _fetchUserStatus(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Loading indicator
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Display error if any
        }
        if (snapshot.hasData) {
          bool isOnline = snapshot.data ?? false;

          return Align(
            alignment: Alignment.bottomRight,
            child: CustomSwitch(
              value: isOnline,
              onChanged: (value) {
                print('widget.userId: ${widget.userId}');
                print('Table: $table');
                // Here, you can update the Firestore document if needed
                FirebaseFirestore.instance
                    .collection(table)
                    .doc(widget.userId)
                    .update({'isOnline': value});
              },
            ),
          );
        }
        return Text('No model found');
      },
    );
  }
}
