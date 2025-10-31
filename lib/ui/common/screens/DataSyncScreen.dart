import 'package:broker_flutter_pp/ui/auth/screens/Login.dart';
import 'package:broker_flutter_pp/ui/common/screens/DrawerScreen.dart';
import 'package:broker_flutter_pp/ui/common/screens/SplashScreen.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/bridges/AirportService.dart';


class DataSyncScreen extends StatefulWidget {
  const DataSyncScreen({Key? key}) : super(key: key);

  @override
  State<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends State<DataSyncScreen> {
  String statusMessage = 'Starting synchronization...';

  @override
  void initState() {
    super.initState();
    startSyncProcess();
  }

  Future<void> startSyncProcess() async {
    int retryCount = 0;

    while (true) {
      // 🔌 Internet check
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() => statusMessage = 'No internet connection. Please connect to the internet.');
        await Future.delayed(const Duration(seconds: 5));
        continue; // wait and try again
      }

      try {
        setState(() => statusMessage = 'Fetching data (attempt ${retryCount + 1})...');
        await Future.delayed(const Duration(seconds: 1));

        final AirportService service = AirportService();
        await service.loadAirports();

        setState(() => statusMessage = 'Data synchronized. Requesting location permission...');
        await Future.delayed(const Duration(seconds: 1));

        // ✅ Save sync flag
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isDataSynced', true);

        await handleLocationPermission(); // ye navigate karega
        break; // exit loop if all done
      } catch (e) {
        retryCount++;
        setState(() => statusMessage = 'Sync failed (attempt $retryCount). Retrying in ${2 * retryCount} seconds...');
        await Future.delayed(Duration(seconds: 2 * retryCount));
      }
    }
  }


  Future<void> handleLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      checkRememberMe(context); // ✅ function now declared properly

/*      // Navigate to login/home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );*/
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')));
      // Optionally retry or stay on screen
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0), // responsive padding
          child: Column(
            mainAxisSize: MainAxisSize.min, // content centered vertically
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/syncing.json',
                width: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
