import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/broker/model/BrokerProfileData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (roleProvider.role == UserRole.broker) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BrokerProfileScreen(
                                      brokerProfile: brokerProfile,
                                    ),
                                  ),
                                );
                              } else if (roleProvider.role == UserRole.courier) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourierProfile(),
                                  ),
                                );
                              }
                            },
                            child: FutureBuilder<String?>(
                              future: _getProfileImageUrl(roleProvider.role),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 60,
                                    width: 60,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  );
                                }

                                final imageUrl = snapshot.data;
                                return CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 30,
                                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                                      ? NetworkImage("$imageUrl?${DateTime.now().millisecondsSinceEpoch}")
                                      : const AssetImage('assets/avatar.png') as ImageProvider,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<String>(
                            future: getUserName(roleProvider.role),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text(
                                  'Loading...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              } else if (snapshot.hasError) {
                                return const Text(
                                  'Error loading name',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              } else {
                                return Text(
                                  snapshot.data ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<String?>(
                      future: AuthUtils.getCurrentUserId(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return Text('Error: ${snapshot.error ?? "No user ID found"}');
                        }

                        String? userId = snapshot.data;
                        if (userId == null) {
                          return const Text("No user logged in");
                        }

                        return Align(
                          alignment: Alignment.bottomRight,
                          child: SwitchWithOnlineStatus(userId: userId),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _getProfileImageUrl(UserRole role) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final firestore = FirebaseFirestore.instance;
    try {
      final doc = await firestore
          .collection(role == UserRole.broker ? 'broker' : 'courier')
          .doc(uid)
          .get();

      if (doc.exists) {
        return doc.data()?['profilePictureUrl'] as String?;
      }
    } catch (e) {
      print("Error fetching profile image: $e");
    }

    return null;
  }
}

Future<String> getUserName(UserRole role) async {
  final userId = await AuthUtils.getCurrentUserId();

  if (userId == null) return 'Unknown';

  final collection = (role == UserRole.courier) ? 'courier' : 'broker';

  final docSnapshot =
  await FirebaseFirestore.instance.collection(collection).doc(userId).get();

  if (docSnapshot.exists) {
    return docSnapshot.data()?['name'] ?? 'N/A';
  } else {
    return 'User Not Found';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 50, // Height remains optimal
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Wider Switch
            GestureDetector(
              onTap: _toggleSwitch,
              child: Container(
                width: 100.0, // ⬅️ Increased from 60 → 70
                height: 30.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: _value ? Colors.green : Colors.grey,
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment:
                      _value ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 35.0,
                        height: 35.0,
                        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Text
            Text(
              _value ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold, // 💪 Fully bold
                color: _value ? Colors.white : Colors.grey[700], // ✅ Status color
              ),
            ),


          ],
        ),
      ),
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
