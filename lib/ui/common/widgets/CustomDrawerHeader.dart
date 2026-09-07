import 'dart:io';

import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/widgets/ProfileAvatar.dart';
import 'package:broker_flutter_pp/ui/common/utils/OnlineStatusProvider.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/broker/BrokerProfileScreen.dart';
import 'package:provider/provider.dart';
import '../../courier/CourierProfile.dart';
import '../utils/AuthUtils.dart';

class CustomDrawerHeader extends StatelessWidget {
  CustomDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final brokerProfile = Provider.of<RoleProvider>(context).brokerProfile;
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    final isBroker = roleProvider.role == UserRole.broker;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: Palette.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar + online switch row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile avatar
                  GestureDetector(
                    onTap: () async {
                      if (await _handleOfflineOrNoInternet(context)) {
                        if (isBroker) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BrokerProfileScreen(brokerProfile: brokerProfile),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourierProfile()),
                          );
                        }
                      }
                    },
                    child: Stack(
                      children: [
                        FutureBuilder<String?>(
                          future: _getProfileImageUrl(roleProvider.role),
                          builder: (context, snapshot) {
                            final imageUrl = snapshot.data;
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ProfileAvatar(
                                url: imageUrl,
                                radius: 34,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                iconColor: Colors.white70,
                              ),
                            );
                          },
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Palette.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Online/Offline switch
                  FutureBuilder<String?>(
                    future: AuthUtils.getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final userId = snapshot.data!;
                      return SwitchWithOnlineStatus(userId: userId);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Name
              FutureBuilder<String>(
                future: getUserName(roleProvider.role),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? '...';
                  return Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  );
                },
              ),

              const SizedBox(height: 4),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBroker ? Icons.business_center_rounded : Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isBroker ? 'Broker' : 'Courier',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _handleOfflineOrNoInternet(BuildContext context) async {
    final onlineStatus = Provider.of<OnlineStatusProvider>(context, listen: false);

    String? message;
    IconData? icon;
    Color? backgroundColor;

    if (!await isInternetAvailable()) {
      message = 'No Internet Connection, Try again';
      icon = Icons.wifi_off_rounded;
      backgroundColor = Palette.errorColor;
    } else if (!onlineStatus.isOnline) {
      message = 'You are currently offline';
      icon = Icons.cancel_rounded;
      backgroundColor = Palette.warning;
    }

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(message),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
      return false;
    }
    return true;
  }

  Future<bool> isInternetAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _getProfileImageUrl(UserRole role) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
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
  final docSnapshot = await FirebaseFirestore.instance.collection(collection).doc(userId).get();
  if (docSnapshot.exists) {
    return docSnapshot.data()?['name'] ?? 'N/A';
  }
  return 'User Not Found';
}

// ─── Online/Offline Switch ────────────────────────────────────────────────────

class CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomSwitch({super.key, required this.value, required this.onChanged});

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

  void _toggleSwitch(BuildContext context) {
    setState(() => _value = !_value);
    final onlineStatus = Provider.of<OnlineStatusProvider>(context, listen: false);
    onlineStatus.setOnline(_value);
    widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _toggleSwitch(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 88,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: _value ? Palette.success.withOpacity(0.85) : Colors.white.withOpacity(0.25),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: _value ? const Alignment(0.75, 0) : const Alignment(-0.75, 0),
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: _value ? const Alignment(-0.6, 0) : const Alignment(0.6, 0),
              child: Text(
                _value ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _value ? Colors.white : Colors.white70,
                  letterSpacing: 0.5,
                ),
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

  Future<bool> _fetchUserStatus(BuildContext context) async {
    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      table = roleProvider.role == UserRole.broker ? "broker" : "courier";
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(table)
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        return userDoc['isOnline'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error fetching user status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _fetchUserStatus(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 88,
            height: 34,
            child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))),
          );
        }
        final isOnline = snapshot.data ?? false;
        return CustomSwitch(
          value: isOnline,
          onChanged: (value) {
            FirebaseFirestore.instance
                .collection(table)
                .doc(widget.userId)
                .update({'isOnline': value});
          },
        );
      },
    );
  }
}
