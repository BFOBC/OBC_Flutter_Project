import 'package:broker_flutter_pp/ui/common/screens/MapScreen.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/common/widgets/CustomDrawerHeader.dart';
import 'package:provider/provider.dart';
import '../../../res/strings.dart';
import '../../broker/CourierMap.dart';
import '../../broker/MyMissions.dart';
import '../../broker/NotificationScreen.dart';
import '../../broker/SettingScreen.dart';
import '../../broker/emptyleg/SearchEmptyLeg.dart';
import '../../chat/ChatScreen.dart';
import '../utils/RoleProvider.dart';
import 'Home.dart';
import 'NotificationsScreen.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({Key? key}) : super(key: key);

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
        ? const CourierMap(title: AppStrings.map)
        : const OpenStreetMapScreen(title: AppStrings.map);
  }

  void _onItemSelected(String title) {
    setState(() {
      switch (title) {
        case AppStrings.map:
          _initializeSelectedWidget();
          _showSnackBar('Logged in as ${Provider.of<RoleProvider>(context, listen: false).role == UserRole.broker ? 'Broker' : 'Courier'}');
          break;
        case AppStrings.notifications:
          _selectedWidget = const NotificationScreen();
          break;
        case AppStrings.availabilityUpdates:
          _selectedWidget = const SearchEmptyLegScreen();
          break;
        case AppStrings.chat:
          _selectedWidget = const ChatScreen();
          break;
        case AppStrings.myMissions:
          _selectedWidget = const MyMissions();
          break;
        case AppStrings.history:
        case AppStrings.inviteFriends:
        case AppStrings.faq:
        case AppStrings.settings:
        _selectedWidget = const SettingScreen();
        default:
          _selectedWidget = const OpenStreetMapScreen(title: AppStrings.map);
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

    return Scaffold(
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
            const CustomDrawerHeader(),
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
    );
  }
}

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DrawerItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
