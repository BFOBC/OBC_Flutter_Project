import 'dart:io';

import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/auth/screens/Login.dart';
import 'package:broker_flutter_pp/ui/broker/mission/BrokerMissions.dart';
import 'package:broker_flutter_pp/ui/chat/ChatListScreen.dart';
import 'package:broker_flutter_pp/ui/common/screens/FAQSScreen.dart';
import 'package:broker_flutter_pp/ui/common/screens/NotificationsScreen.dart';
import 'package:broker_flutter_pp/ui/common/utils/OnlineStatusProvider.dart';
import 'package:broker_flutter_pp/ui/courier/CourierMap.dart';
import 'package:broker_flutter_pp/ui/courier/emptyleg/JobCardStackWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/common/widgets/CustomDrawerHeader.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../res/strings.dart';
import '../../broker/BrokerMap.dart';
import 'SettingScreen.dart';
import '../../broker/emptyleg/SearchEmptyLeg.dart';
import '../../courier/missions/CourierMissions.dart';
import '../../courier/emptyleg/EmptyLegMainScreen.dart';
import '../utils/RoleProvider.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  _DrawerScreenState createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  late Widget _selectedWidget;

  final Map<String, Map<String, dynamic>> _drawerItems = {
    AppStrings.map: {
      'title': AppStrings.map,
      'icon': Icons.map,
    },
    AppStrings.availabilityUpdates: {
      'title': AppStrings.availabilityUpdates,
      'icon': Icons.update,
    },
    AppStrings.myMissions: {
      'title': AppStrings.myMissions,
      'icon': Icons.access_alarm,
    },
    AppStrings.notifications: {
      'title': AppStrings.notifications,
      'icon': Icons.notifications,
    },
    AppStrings.chat: {
      'title': AppStrings.chat,
      'icon': Icons.chat,
    },
/*    AppStrings.history: {
      'title': AppStrings.history,
      'icon': Icons.history,
    },
    AppStrings.inviteFriends: {
      'title': AppStrings.inviteFriends,
      'icon': Icons.people,
    },*/
    AppStrings.faq: {
      'title': AppStrings.faq,
      'icon': Icons.help,
    },
    AppStrings.logout: {
      'title': AppStrings.logout,
      'icon': Icons.logout,
    },
/*    AppStrings.settings: {
      'title': AppStrings.settings,
      'icon': Icons.settings,
    }*/
  };

  @override
  void initState() {
    super.initState();
    _initializeSelectedWidget();
    generateToken();
  }

  Future<void> generateToken() async {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      String? uid = FirebaseAuth.instance.currentUser?.uid;

      // Determine the correct collection based on role
      String collectionName =
      roleProvider.role == UserRole.broker ? 'broker' : 'courier';

      // Save the token in the correct collection
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .set({
        'fcm_token': token,
      }, SetOptions(merge: true));
    }

  }

  void _initializeSelectedWidget() {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    _selectedWidget = roleProvider.role == UserRole.broker
        ? const BrokerMap(title: AppStrings.map)
        : const CourierMap(title: AppStrings.map);
  }

  Future<void> _onItemSelected(String title) async {
    final onlineStatus =
        Provider.of<OnlineStatusProvider>(context, listen: false);
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    String? message;
    IconData? icon;
    Color? backgroundColor;

    // ✅ Internet not available
    if (!await isInternetAvailable()) {
      message = 'No Internet Connection, Try again';
      icon = Icons.wifi_off;
      backgroundColor = Colors.redAccent;

      // Set default screen
      setState(() {
        if (roleProvider.role == UserRole.broker) {
          _selectedWidget = const BrokerMap(title: AppStrings.map);
        } else if (roleProvider.role == UserRole.courier) {
          _selectedWidget = const CourierMap(title: AppStrings.map);
        }
      });

      // ✅ User is offline and trying to go online
    } else if (!onlineStatus.isOnline) {
      message = 'You are currently offline';
      icon = Icons.cancel;
      backgroundColor = Colors.orange;
    }

    // ✅ If any of the above checks failed
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      Navigator.pop(context);
      return;
    }

    // ✅ Proceed only if internet is available and user if online
    setState(() {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);

      switch (title) {
        case AppStrings.map:
          _initializeSelectedWidget();
          break;

        case AppStrings.notifications:
          _selectedWidget = const NotificationsScreen();
          break;

        case AppStrings.availabilityUpdates:
          if (roleProvider.role == UserRole.broker) {
            _selectedWidget = SearchEmptyLegScreen();
          } else {
            _selectedWidget = const JobCardStackWidget();
          }
          break;

        case AppStrings.chat:
          User? user = FirebaseAuth.instance.currentUser;
          _selectedWidget = ChatListScreen(userId: user!.uid.toString());
          break;

        case AppStrings.myMissions:
          if (roleProvider.role == UserRole.broker) {
            _selectedWidget = BrokerMissions();
          } else {
            _selectedWidget = const CourierMissions();
          }
          break;

        case AppStrings.history:
        case AppStrings.inviteFriends:
        case AppStrings.faq:
        _selectedWidget=const  FAQSScreen();
        case AppStrings.logout:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _logout(context);
          });
          break;

        case AppStrings.settings:
          _selectedWidget =const  SettingScreen();
          break;

        default:
          _selectedWidget = const CourierMap(title: AppStrings.map);
          break;
      }
    });

    Navigator.pop(context); // close drawer after selection
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> isInternetAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    var title = roleProvider.role == UserRole.broker ? 'Broker' : 'Courier';

    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await _showExitDialog(context);
        return shouldExit; // Return Future<bool> indicating whether to exit
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ),
        drawer: Drawer(
          child: Column(
            children: [
              CustomDrawerHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _drawerItems.keys.map((String key) {
                    return DrawerItem(
                      icon: _drawerItems[key]!['icon'],
                      title: _drawerItems[key]!['title'],
                      onTap: () => _onItemSelected(key),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        body: _selectedWidget,
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // User must choose Yes/No
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: const [
                  Icon(Icons.exit_to_app, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    "Exit App",
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              content: const Text(
                "Are you sure you want to exit the app?",
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Don't exit
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                  child: const Text("No"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Exit
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Yes"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable tap outside to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          title: Row(
            children: const [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                await clearSavedLoginData(context);
                // 3. Navigate to login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginCard()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}

Future<void> clearSavedLoginData(BuildContext context) async {
  // Get role from Provider
  final roleProvider = Provider.of<RoleProvider>(context, listen: false);
  FirestoreService service = FirestoreService(context);

  // Decide collection name based on role
  String collection =
  roleProvider.role == UserRole.courier ? 'courier' : 'broker';

  await service.setUserOffline();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('email');
  await prefs.remove('password');
  await prefs.remove('rememberMe');
  await prefs.remove('role');
}

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
