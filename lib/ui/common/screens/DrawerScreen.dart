import 'package:broker_flutter_pp/ui/broker/BrokerNotificationsScreen.dart';
import 'package:broker_flutter_pp/ui/chat/ChatListScreen.dart';
import 'package:broker_flutter_pp/ui/common/screens/NotificationsScreen.dart';
import 'package:broker_flutter_pp/ui/courier/CourierMap.dart';
import 'package:broker_flutter_pp/ui/courier/CourierNotificationsScreen.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/common/widgets/CustomDrawerHeader.dart';
import 'package:provider/provider.dart';
import '../../../res/strings.dart';
import '../../broker/BrokerMap.dart';
import '../../broker/BrokerMissions.dart';
import '../../broker/NotificationScreen.dart';
import '../../broker/SettingScreen.dart';
import '../../broker/emptyleg/SearchEmptyLeg.dart';
import '../../courier/CourierMissions.dart';
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
    AppStrings.notifications: {
      'title': AppStrings.notifications,
      'icon': Icons.notifications,
    },
    AppStrings.availabilityUpdates: {
      'title': AppStrings.availabilityUpdates,
      'icon': Icons.update,
    },
    AppStrings.chat: {
      'title': AppStrings.chat,
      'icon': Icons.chat,
    },
    AppStrings.myMissions: {
      'title': AppStrings.myMissions,
      'icon': Icons.access_alarm,
    },
    AppStrings.history: {
      'title': AppStrings.history,
      'icon': Icons.history,
    },
    AppStrings.inviteFriends: {
      'title': AppStrings.inviteFriends,
      'icon': Icons.people,
    },
    AppStrings.faq: {
      'title': AppStrings.faq,
      'icon': Icons.help,
    },
    AppStrings.settings: {
      'title': AppStrings.settings,
      'icon': Icons.settings,
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeSelectedWidget();
  }

  void _initializeSelectedWidget() {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    _selectedWidget = roleProvider.role == UserRole.broker
        ? const BrokerMap(title: AppStrings.map)
        : const CourierMap(title: AppStrings.map);
  }

  void _onItemSelected(String title) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    if (roleProvider.role == UserRole.broker) {
      _selectedWidget = const BrokerMap(title: AppStrings.map);
    } else if (roleProvider.role == UserRole.courier) {
      _selectedWidget = const CourierMap(title: AppStrings.map);
    }
    setState(() {
      switch (title) {
        case AppStrings.map:
          _initializeSelectedWidget();
          _showSnackBar(
              'Logged in as ${Provider.of<RoleProvider>(context, listen: false).role == UserRole.broker ? 'Broker' : 'Courier'}');
          break;
        case AppStrings.notifications:
          _selectedWidget = const NotificationsScreen();
/*          if (roleProvider.role == UserRole.broker) {
            _selectedWidget = BrokerNotificationsScreen();
          } else if (roleProvider.role == UserRole.courier) {
            _selectedWidget = const BrokerNotificationsScreen();
          }*/
          break;
        case AppStrings.availabilityUpdates:
          if (roleProvider.role == UserRole.broker) {
            _showSnackBar("I am Broker");
            _selectedWidget = SearchEmptyLegScreen();
          } else if (roleProvider.role == UserRole.courier) {
            _showSnackBar("I am Courier");
            _selectedWidget = const EmptyLegMainScreen();
          }
          break;
        case AppStrings.chat:
          _selectedWidget = ChatListScreen();
          break;
        case AppStrings.myMissions:
          if (roleProvider.role == UserRole.broker) {
            _selectedWidget =  Brokermissions();
          } else if (roleProvider.role == UserRole.courier) {
            _selectedWidget = const CourierMissions();
          }
          break;
        case AppStrings.history:
        case AppStrings.inviteFriends:
        case AppStrings.faq:
        case AppStrings.settings:
          _selectedWidget = const SettingScreen();
        default:
          _selectedWidget = const CourierMap(title: AppStrings.map);
          break;
      }
    });
    Navigator.pop(context);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Exit"),
          content: const Text("Are you sure you want to exit the app?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't exit
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Exit
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    ) ?? false; // Default to not exiting if dialog is dismissed
  }
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
