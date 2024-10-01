import 'package:broker_flutter_pp/ui/auth/screens/Login.dart';
import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Account Settings
              _buildSettingOption(
                icon: Icons.account_circle,
                title: 'Account Settings',
                subtitle: 'Manage your account information',
                onTap: () {
                  // Navigate to Account Settings Screen
                },
              ),

              const SizedBox(height: 20),

              // Notification Settings
              _buildSettingOption(
                icon: Icons.notifications,
                title: 'Notification Settings',
                subtitle: 'Customize your notification preferences',
                onTap: () {
                  // Navigate to Notification Settings Screen
                },
              ),

              const SizedBox(height: 20),

              // Privacy Settings
              _buildSettingOption(
                icon: Icons.lock,
                title: 'Privacy Settings',
                subtitle: 'Manage your privacy and security',
                onTap: () {
                  // Navigate to Privacy Settings Screen
                },
              ),

              const SizedBox(height: 20),

              // Language Settings
              _buildSettingOption(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'Choose your preferred language',
                onTap: () {
                  _showLanguageDialog(context);
                },
              ),

              const SizedBox(height: 20),

              // Logout Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _logout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Language selection dialog
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                onTap: () {
                  _applyLanguage('English');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('German'),
                onTap: () {
                  _applyLanguage('German');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Russian'),
                onTap: () {
                  _applyLanguage('Russian');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to apply selected language (dummy function for now)
  void _applyLanguage(String language) {
    print('Selected Language: $language');
  }

  // Logout method to show confirmation dialog
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginCard()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build each setting option
  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.blueAccent),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
