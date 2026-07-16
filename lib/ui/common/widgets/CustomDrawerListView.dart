import 'package:flutter/material.dart';

class CustomDrawerListView extends StatelessWidget {
  const CustomDrawerListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerItem(
          icon: Icons.home,
          title: 'Home',
          onTap: () {
            // Handle Home option
            Navigator.pop(context); // Close the drawer
          },
        ),
        DrawerItem(
          icon: Icons.notifications,
          title: 'Notification',
          onTap: () {
            // Handle Settings option
            Navigator.pop(context); // Close the drawer
          },
        ),
        DrawerItem(
          icon: Icons.map,
          title: 'Map',
          onTap: () {
            // Handle Settings option
            Navigator.pop(context); // Close the drawer
          },
        ),
        DrawerItem(
          icon: Icons.timer,
          title: 'Availability Updates',
          onTap: () {
            // Handle Settings option
            Navigator.pop(context); // Close the drawer
          },
        ),
        DrawerItem(
          icon: Icons.chat,
          title: 'Chat',
          onTap: () {
            // Handle Settings option
            Navigator.pop(context); // Close the drawer
          },
        ),
        DrawerItem(
          icon: Icons.arrow_upward,
          title: 'My Missions',
          onTap: () {
            // Handle Settings option
            Navigator.pop(context); // Close the drawer
          },
        ),
        DrawerItem(
          icon: Icons.history,
          title: 'History',
          onTap: () {
            // Handle Settings option
            Navigator.pop(context); // Close the drawer
          },
        ),
        DrawerItem(
          icon: Icons.chat_bubble,
          title: 'FAQ',
          onTap: () {
            // Handle Settings option
            Navigator.pop(context); // Close the drawer
          },
        ),
        DrawerItem(
          icon: Icons.card_giftcard,
          title: 'Invite Friends',
          onTap: () {
            // Handle Settings option
            Navigator.pop(context); // Close the drawer
          },
        ),
        DrawerItem(
          icon: Icons.settings,
          title: 'Settings',
          onTap: () {
            // Handle Settings option
            Navigator.pop(context); // Close the drawer
          },
        ),
        DrawerItem(
          icon: Icons.logout,
          title: 'Logout',
          onTap: () {
            // Handle Settings option
            Navigator.pop(context); // Close the drawer
          },
        ),
      ],
    );
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