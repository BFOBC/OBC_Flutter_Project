import 'dart:io';

import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
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
  String _activeTitle = AppStrings.map;

  final Map<String, Map<String, dynamic>> _drawerItems = {
    AppStrings.map: {
      'title': AppStrings.map,
      'icon': Icons.map_rounded,
    },
    AppStrings.availabilityUpdates: {
      'title': AppStrings.availabilityUpdates,
      'icon': Icons.flight_rounded,
    },
    AppStrings.myMissions: {
      'title': AppStrings.myMissions,
      'icon': Icons.task_alt_rounded,
    },
    AppStrings.notifications: {
      'title': AppStrings.notifications,
      'icon': Icons.notifications_rounded,
    },
    AppStrings.chat: {
      'title': AppStrings.chat,
      'icon': Icons.chat_bubble_rounded,
    },
    AppStrings.faq: {
      'title': AppStrings.faq,
      'icon': Icons.help_outline_rounded,
    },
    AppStrings.logout: {
      'title': AppStrings.logout,
      'icon': Icons.logout_rounded,
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeSelectedWidget();
    generateToken();
  }

  Future<void> generateToken() async {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      String collectionName = roleProvider.role == UserRole.broker ? 'broker' : 'courier';
      await FirebaseFirestore.instance.collection(collectionName).doc(uid).set(
        {'fcm_token': token},
        SetOptions(merge: true),
      );
    }
  }

  void _initializeSelectedWidget() {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    _selectedWidget = roleProvider.role == UserRole.broker
        ? const BrokerMap(title: AppStrings.map)
        : const CourierMap(title: AppStrings.map);
  }

  Future<void> _onItemSelected(String title) async {
    final onlineStatus = Provider.of<OnlineStatusProvider>(context, listen: false);
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    String? message;
    IconData? icon;
    Color? backgroundColor;

    if (!await isInternetAvailable()) {
      message = 'No Internet Connection, Try again';
      icon = Icons.wifi_off_rounded;
      backgroundColor = Palette.errorColor;

      setState(() {
        if (roleProvider.role == UserRole.broker) {
          _selectedWidget = const BrokerMap(title: AppStrings.map);
        } else if (roleProvider.role == UserRole.courier) {
          _selectedWidget = const CourierMap(title: AppStrings.map);
        }
      });
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
      return;
    }

    setState(() {
      _activeTitle = title;
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
          _selectedWidget = const FAQSScreen();
          break;
        case AppStrings.logout:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _logout(context);
          });
          break;
        case AppStrings.settings:
          _selectedWidget = const SettingScreen();
          break;
        default:
          _selectedWidget = const CourierMap(title: AppStrings.map);
          break;
      }
    });

    Navigator.pop(context);
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
    final isBroker = roleProvider.role == UserRole.broker;
    final roleLabel = isBroker ? 'Broker' : 'Courier';
    final roleColor = isBroker ? Palette.primaryColor : Palette.secondaryDark;

    return WillPopScope(
      onWillPop: () async => await _showExitDialog(context),
      child: Scaffold(
        backgroundColor: Palette.backgroundLight,
        appBar: AppBar(
          backgroundColor: Palette.primaryColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                onPressed: () => Scaffold.of(context).openDrawer(),
                splashRadius: 22,
              );
            },
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBroker ? Icons.business_center_rounded : Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      roleLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => _onItemSelected(AppStrings.notifications),
              splashRadius: 22,
            ),
            const SizedBox(width: 4),
          ],
        ),
        drawer: Drawer(
          width: 285,
          child: Column(
            children: [
              CustomDrawerHeader(),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  children: [
                    ..._drawerItems.keys
                        .where((k) => k != AppStrings.logout)
                        .map((String key) => _DrawerNavItem(
                              icon: _drawerItems[key]!['icon'],
                              title: _drawerItems[key]!['title'],
                              isActive: _activeTitle == key,
                              onTap: () => _onItemSelected(key),
                            )),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    _DrawerNavItem(
                      icon: _drawerItems[AppStrings.logout]!['icon'],
                      title: _drawerItems[AppStrings.logout]!['title'],
                      isActive: false,
                      isDestructive: true,
                      onTap: () => _onItemSelected(AppStrings.logout),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  'OBC Smart v1.0',
                  style: TextStyle(fontSize: 11, color: Palette.textDisabled),
                  textAlign: TextAlign.center,
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
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Palette.errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.exit_to_app_rounded, color: Palette.errorColor, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Exit App',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Palette.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Are you sure you want to exit?',
                      style: TextStyle(fontSize: 14, color: Palette.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Palette.textSecondary,
                              side: const BorderSide(color: Palette.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.errorColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Exit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Palette.errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Palette.errorColor, size: 28),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Logout',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Palette.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to log out?',
                  style: TextStyle(fontSize: 14, color: Palette.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.textSecondary,
                          side: const BorderSide(color: Palette.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await clearSavedLoginData(context);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginCard()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> clearSavedLoginData(BuildContext context) async {
  final roleProvider = Provider.of<RoleProvider>(context, listen: false);
  FirestoreService service = FirestoreService(context);
  await service.setUserOffline();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('email');
  await prefs.remove('password');
  await prefs.remove('rememberMe');
  await prefs.remove('role');
}

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = Palette.primaryColor;
    final destructiveColor = Palette.errorColor;
    final itemColor = isDestructive ? destructiveColor : (isActive ? activeColor : Palette.textSecondary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive ? Palette.primaryColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: (isDestructive ? destructiveColor : activeColor).withOpacity(0.12),
          highlightColor: (isDestructive ? destructiveColor : activeColor).withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Palette.primaryColor.withOpacity(0.12)
                        : isDestructive
                            ? Palette.errorColor.withOpacity(0.08)
                            : Palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: itemColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: itemColor,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Palette.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Legacy DrawerItem kept for compatibility
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
    return _DrawerNavItem(icon: icon, title: title, isActive: false, onTap: onTap);
  }
}
