import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/auth/SignIn.dart';
import 'package:broker_flutter_pp/ui/broker/BrokerProfileScreen.dart';
import 'package:broker_flutter_pp/ui/courier/CourierProfile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/utils/dialog_utils.dart';
import 'package:broker_flutter_pp/ui/common/utils/validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/screens/DrawerScreen.dart';
import '../../common/utils/RoleProvider.dart';
import '../widgets/PasswordField.dart';

class LoginCard extends StatelessWidget {
  const LoginCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Palette.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top branding area
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'OBC SMART',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Logistics Courier Platform',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Login card
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Palette.backgroundLight,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: CardView(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardView extends StatefulWidget {
  const CardView({super.key});

  @override
  _CardViewState createState() => _CardViewState();
}

class _CardViewState extends State<CardView> {
  final TextEditingController _emailController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(text: '');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;

  int _selectedIndex = 0;

  String get emailHint =>
      _selectedIndex == 0 ? 'Enter Broker Email' : 'Enter Courier Email';

  final List<bool> _selectedToggle = [true, false];
  final List<String> _toggleText = ["Broker", "Courier"];

  Future<void> _submitForm() async {
    print("SubmitForm called");

    if (!_formKey.currentState!.validate()) {
      print("Form validation failed");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fix the errors in the form"),
            backgroundColor: Palette.warning,
          ),
        );
      }
      return;
    }

    print("Form validated");
    showProgressDialog(context);

    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      final role = _selectedIndex == 0 ? UserRole.broker : UserRole.courier;
      roleProvider.setRole(role);

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await signInAndSaveUser(email, password, _selectedIndex);

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('email', email);
        await prefs.setString('password', password);
        await prefs.setBool('rememberMe', true);
        await prefs.setString('role', role == UserRole.broker ? 'Broker' : 'Courier');
      } else {
        await prefs.remove('email');
        await prefs.remove('password');
        await prefs.setBool('rememberMe', false);
        await prefs.remove('role');
      }

      if (context.mounted) hideProgressDialog(context);

      if (result != null && result.containsKey('error')) {
        final errorMessage = result['error'];

        if (context.mounted) {
          if (errorMessage == "Blocked user") {
            showBlockedDialog(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Palette.errorColor,
              ),
            );
          }
        }
        return;
      }

      final isProfileCompleted = result?['isProfileCompleted'] ?? false;

      if (!isProfileCompleted) {
        if (context.mounted) {
          if (role == UserRole.broker) {
            final brokerProfile = Provider.of<RoleProvider>(context, listen: false).brokerProfile;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => BrokerProfileScreen(brokerProfile: brokerProfile)),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => CourierProfile()),
            );
          }
        }
      } else {
        FirestoreService service = FirestoreService(context);
        service.setUserOnline();
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DrawerScreen()),
          );
        }
      }

    } catch (e) {
      if (context.mounted) hideProgressDialog(context);
      print("Exception occurred: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Something went wrong. Please try again."),
            backgroundColor: Palette.errorColor,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> signInAndSaveUser(String email, String password, int selectedIndex) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;
      print("✅ Login successful: $uid");

      String selectedRole = selectedIndex == 0 ? 'broker' : 'courier';

      DocumentSnapshot brokerDoc = await FirebaseFirestore.instance.collection('broker').doc(uid).get();
      DocumentSnapshot courierDoc = await FirebaseFirestore.instance.collection('courier').doc(uid).get();

      String? actualRole;
      DocumentSnapshot? userDoc;

      if (brokerDoc.exists) {
        actualRole = 'broker';
        userDoc = brokerDoc;
      } else if (courierDoc.exists) {
        actualRole = 'courier';
        userDoc = courierDoc;
      }

      if (actualRole != null && actualRole != selectedRole) {
        await FirebaseAuth.instance.signOut();
        return {'error': "This email is registered as a $actualRole. Please login using the correct role."};
      }

      if (userDoc != null && userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        Map<String, dynamic> updates = {};

        if (!data.containsKey('id')) updates['id'] = uid;
        if (!data.containsKey('createdAt')) updates['createdAt'] = FieldValue.serverTimestamp();
        if (!data.containsKey('blockedUser')) updates['blockedUser'] = false;
        if (!data.containsKey('isProfileCompleted')) updates['isProfileCompleted'] = false;
        if (!data.containsKey('role')) updates['role'] = actualRole;
        if (!data.containsKey('email')) updates['email'] = email;
        if (!data.containsKey('name')) updates['name'] = actualRole == 'courier' ? 'Test Courier' : 'Test Broker';
        if (!data.containsKey('isOnline')) updates['isOnline'] = true;
        if (!data.containsKey('profilePictureUrl')) updates['profilePictureUrl'] = 'https://mopogotechnologies.com/assets/images/profiles/place_holder_man.png';
        if (actualRole == 'courier') {
          if (!data.containsKey('courierID')) updates['courierID'] = uid;
          if (!data.containsKey('baseLocationLat')) updates['baseLocationLat'] = 51.1657;
          if (!data.containsKey('baseLocationLong')) updates['baseLocationLong'] = 10.4515;
          if (!data.containsKey('currentLocationLat')) updates['currentLocationLat'] = 51.1657;
          if (!data.containsKey('currentLocationLong')) updates['currentLocationLong'] = 10.4515;
          if (!data.containsKey('country')) updates['country'] = 'Germany';
          if (!data.containsKey('base')) updates['base'] = true;
          if (!data.containsKey('current')) updates['current'] = false;
        }

        if (actualRole == 'broker' && !data.containsKey('brokerID')) {
          updates['brokerID'] = uid;
        }

        if (updates.isNotEmpty) {
          await userDoc.reference.set(updates, SetOptions(merge: true));
          print("✅ Auto-filled missing fields for $actualRole.");
          data.addAll(updates);
        }

        if (data['blockedUser'] == true) {
          await FirebaseAuth.instance.signOut();
          return {'error': "Blocked user"};
        }

        return data;
      }

      await FirebaseAuth.instance.signOut();
      return {'error': "No role assigned to this account. Please contact support."};

    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Error: ${e.code} - ${e.message}");
      return {'error': e.message ?? "Authentication failed."};
    } catch (e) {
      print("❌ Unknown error: $e");
      return {'error': "Something went wrong. Please try again."};
    }
  }

  void showBlockedDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Account Blocked",
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Palette.errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.block_rounded, color: Palette.errorColor, size: 36),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Account Deactivated",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Your account is not active.\nPlease contact support +923065000660.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Palette.textSecondary, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          FirebaseAuth.instance.signOut();
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text("Understood"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role selector
          const Text(
            'Select your role',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Palette.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Palette.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.border, width: 1),
            ),
            child: Row(
              children: List.generate(_toggleText.length, (index) {
                final isSelected = _selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                        _selectedToggle[index] = true;
                        _selectedToggle[1 - index] = false;
                        _emailController.text = '';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Palette.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Palette.primaryColor.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            index == 0 ? Icons.business_center_rounded : Icons.local_shipping_rounded,
                            size: 16,
                            color: isSelected ? Colors.white : Palette.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _toggleText[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 28),
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sign in to continue',
            style: TextStyle(fontSize: 14, color: Palette.textSecondary),
          ),

          const SizedBox(height: 28),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: emailHint,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (value) => Validator.validateEmail(email: value ?? ''),
          ),

          const SizedBox(height: 16),

          // Password field
          PasswordField(controller: _passwordController),

          const SizedBox(height: 8),

          // Remember Me
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  activeColor: Palette.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: const BorderSide(color: Palette.border, width: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Remember Me',
                style: TextStyle(fontSize: 13, color: Palette.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Login button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              child: const Text('Sign In'),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
