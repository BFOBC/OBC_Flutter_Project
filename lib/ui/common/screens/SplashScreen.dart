import 'dart:async';
import 'package:broker_flutter_pp/data/bridges/AirportService.dart';
import 'package:broker_flutter_pp/data/sqflitelocal/DatabaseOperation.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/auth/screens/Login.dart';
import 'package:broker_flutter_pp/ui/broker/BrokerProfileScreen.dart';
import 'package:broker_flutter_pp/ui/common/screens/DataSyncScreen.dart';
import 'package:broker_flutter_pp/ui/common/screens/DrawerScreen.dart';
import 'package:broker_flutter_pp/ui/courier/CourierProfile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/sqflitelocal/DatabaseHelper.dart';
import '../AirportsScreen.dart';
import '../utils/RoleProvider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack)),
    );
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );

    _animController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      _checkSyncStatusAndNavigate();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkSyncStatusAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDataSynced = prefs.getBool('isDataSynced') ?? false;

    if (!isDataSynced) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DataSyncScreen()),
      );
    } else {
      checkRememberMe(context);
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

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        final user = userCredential.user;
        if (user == null) throw Exception("User is null");

        if (roleStr != null) {
          final roleProvider = Provider.of<RoleProvider>(context, listen: false);
          final role = roleStr == 'Broker' ? UserRole.broker : UserRole.courier;
          roleProvider.setRole(role);

          final collectionName = role == UserRole.broker ? 'broker' : 'courier';
          final docRef = FirebaseFirestore.instance.collection(collectionName).doc(user.uid);
          final docSnap = await docRef.get();

          if (!docSnap.exists) {
            _navigateToProfileScreen(context, role);
            return;
          }

          final data = docSnap.data() as Map<String, dynamic>;
          if (!data.containsKey('isProfileCompleted')) {
            await docRef.update({'isProfileCompleted': false});
          }

          final isProfileCompleted = data['isProfileCompleted'] == true;

          if (isProfileCompleted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DrawerScreen()),
            );
          } else {
            _navigateToProfileScreen(context, role);
          }
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginCard()),
          );
        }
      } catch (e) {
        print("Login error: $e");
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

  void _navigateToProfileScreen(BuildContext context, UserRole role) {
    final brokerProfile = Provider.of<RoleProvider>(context, listen: false).brokerProfile;
    if (role == UserRole.broker) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BrokerProfileScreen(brokerProfile: brokerProfile)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CourierProfile()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Palette.heroGradient),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/splash_animation_slow.gif',
                                width: 64,
                                height: 64,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // App name
                          const Text(
                            'OBC SMART',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Logistics Courier Platform',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.8,
                            ),
                          ),

                          const SizedBox(height: 64),

                          // Loading indicator
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
