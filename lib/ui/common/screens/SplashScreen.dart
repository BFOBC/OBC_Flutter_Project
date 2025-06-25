import 'dart:async';
import 'package:broker_flutter_pp/data/AirportService.dart';
import 'package:broker_flutter_pp/data/DatabaseOperation.dart';
import 'package:broker_flutter_pp/ui/auth/screens/Login.dart';
import 'package:broker_flutter_pp/ui/common/screens/DataSyncScreen.dart';
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
      _checkSyncStatusAndNavigate();
    });
  }

  Future<void> _checkSyncStatusAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDataSynced = prefs.getBool('isDataSynced') ?? false;

    if (!isDataSynced) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DataSyncScreen()),
      );
    } else {
      checkRememberMe(context); // ✅ function now declared properly
    }
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
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // ✅ Set role in RoleProvider
        if (roleStr != null) {
          final roleProvider = Provider.of<RoleProvider>(context, listen: false);
          roleProvider.setRole(roleStr == 'Broker' ? UserRole.broker : UserRole.courier);
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DrawerScreen()),
        );
      } catch (e) {
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

