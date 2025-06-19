import 'dart:async';
import 'package:broker_flutter_pp/data/AirportService.dart';
import 'package:broker_flutter_pp/data/DatabaseOperation.dart';
import 'package:broker_flutter_pp/ui/auth/screens/Login.dart';
import 'package:broker_flutter_pp/ui/common/screens/DrawerScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/DatabaseHelper.dart';
import '../AirportsScreen.dart';
import '../utils/RoleProvider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay to simulate splash screen duration
    Future.delayed(const Duration(seconds: 3), () {
      checkRememberMe(context);
    });
  }

  Future<void> checkDatabaseAndPermissions() async {
    final DatabaseOperation dbHelper = DatabaseOperation();


    // Check if model exists in the local database
    bool isDataAvailable = await _isDataAvailable(dbHelper);

    if (!isDataAvailable) {
      // Show SnackBar for synchronization
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data not found. Starting synchronization...')),
      );

      // Data not available, start synchronization
      bool isSynced = await _synchronizeData();

      if (!isSynced) {
        // If synchronization fails, show an error and exit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to synchronize model.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data synchronized successfully.')),
      );
    }
    // Check location permissions after model synchronization
    await checkLocationPermissions();
  }

  Future<bool> _isDataAvailable(DatabaseOperation dbHelper) async {
    try {
      final data = await dbHelper.getAirports(); // Replace with your query
      return data.isNotEmpty;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking database: $e')),
      );
      return false;
    }
  }

  Future<bool> _synchronizeData() async {
    try {
      final AirportService _service = AirportService();
      await _service.loadAirports(); // Sync model
      return true;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error synchronizing model: $error')),
      );
      return false;
    }
  }

  Future<void> checkLocationPermissions() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking location permissions...')),
    );

    if (await Permission.location.isGranted) {
      // Permissions granted, navigate to login screen
/*      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions granted. Navigating to login...')),
      );*/
      //navigateToLoginScreen();
    } else {
      // Permissions not granted, navigate to permission screen
/*      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions not granted. Navigating to permission screen...')),
      );*/
      navigateToPermissionScreen();
    }
  }

  void navigateToLoginScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginCard()),
    );
  }

  void navigateToPermissionScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginCard()),
    );
  }
  void checkRememberMe(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool('rememberMe') ?? false;

    print("rememberMe: $rememberMe");
    if (rememberMe) {
      String email = prefs.getString('email') ?? '';
      String password = prefs.getString('password') ?? '';
      String? roleStr = prefs.getString('role');

      print("✅ Current Shared Preferences:");
      print("Email: ${prefs.getString('email')}");
      print("Password: ${prefs.getString('password')}");
      print("Role: ${prefs.getString('role')}");
      print("Remember Me: ${prefs.getBool('rememberMe')}");

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

        // ✅ Set role in RoleProvider
        if (roleStr != null) {
          final roleProvider = Provider.of<RoleProvider>(context, listen: false);
          roleProvider.setRole(roleStr == 'Broker' ? UserRole.broker : UserRole.courier);
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DrawerScreen()),
        );
      } catch (e) {
        // Login failed; go to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginCard()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginCard()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/broker.jpg'),
            ),
            SizedBox(height: 16.0),
            Text(
              'OBC',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
