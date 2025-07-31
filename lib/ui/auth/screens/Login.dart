
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
import '../../../data/FirestoreService.dart';
import '../../common/screens/DrawerScreen.dart';
import '../../common/utils/RoleProvider.dart';
import '../widgets/PasswordField.dart';

class LoginCard extends StatelessWidget {
  const LoginCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CardView(),
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
/*TextEditingController(text: 'broker@gmail.com');
final TextEditingController _passwordController =
TextEditingController(text: '123456');*/
class _CardViewState extends State<CardView> {
  final TextEditingController _emailController =
      TextEditingController(text: '');
  final TextEditingController _passwordController =
      TextEditingController(text: '');
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
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    print("Form validated");
    showProgressDialog(context);

    try {
      // Set role based on tab selection
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      final role = _selectedIndex == 0 ? UserRole.broker : UserRole.courier;
      roleProvider.setRole(role);

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Attempt login and retrieve result
      final result = await signInAndSaveUser(email, password, _selectedIndex);

      // Save or clear shared preferences based on Remember Me
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

      // Handle login error response
      if (result != null && result.containsKey('error')) {
        final errorMessage = result['error'];

        if (context.mounted) {
          if (errorMessage == "Blocked user") {
            showBlockedDialog(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }

      // Login successful, check profile completion
      final isProfileCompleted = result?['isProfileCompleted'] ?? false;

      if (!isProfileCompleted) {
        if (context.mounted) {
          Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.white,
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Incomplete Profile",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    "You must complete your profile before using the app.",
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK", style: TextStyle(color: Colors.orange)),
                    ),
                  ],
                );
              },
            );
          });

          // Navigate to BrokerProfileScreen or CourierProfile based on role
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
        // Profile is completed, move to home screen
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> signInAndSaveUser(String email, String password, int selectedIndex) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      print("✅ Login successful: ${userCredential.user?.uid}");

      String uid = userCredential.user!.uid;

      // Selected role user ne UI se choose kiya (e.g., index 0 = broker, 1 = courier)
      String selectedRole = selectedIndex == 0 ? 'broker' : 'courier';

      // 🔍 First check both collections to find correct role
      DocumentSnapshot brokerDoc = await FirebaseFirestore.instance
          .collection('broker')
          .doc(uid)
          .get();

      DocumentSnapshot courierDoc = await FirebaseFirestore.instance
          .collection('courier')
          .doc(uid)
          .get();

      String? actualRole;
      DocumentSnapshot? userDoc;
      if (brokerDoc.exists) {
        actualRole = 'broker';
        userDoc = brokerDoc;
      } else if (courierDoc.exists) {
        actualRole = 'courier';
        userDoc = courierDoc;
      }

      // ❌ Mismatch in selected role vs actual
      if (actualRole != null && actualRole != selectedRole) {
        await FirebaseAuth.instance.signOut();
        return {'error': "This email is registered as a $actualRole. Please login using the correct role."};
      }

      // ❌ Check blockUser flag (Safely!)
      if (userDoc != null && userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        final isBlocked = data.containsKey('blockUser') && data['blockUser'] == true;
        if (isBlocked) {
          await FirebaseAuth.instance.signOut();
          return {'error': "Blocked user"};
        }

        // ✅ Also make sure isProfileCompleted key exists
        if (!data.containsKey('isProfileCompleted')) {
          await userDoc.reference.update({'isProfileCompleted': false});
          data['isProfileCompleted'] = false;
        }

        return data; // ✅ Return full data with isProfileCompleted
      }

      // ✅ If role not set yet (first-time login), create new doc
      if (actualRole == null) {
        String collectionName = selectedRole;
        DocumentReference userDocRef =
        FirebaseFirestore.instance.collection(collectionName).doc(uid);

        Map<String, dynamic> userData = {
          'blockedUser': false,
          'email': email,
          'role': selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
          'id': uid,
          'name': selectedRole == 'courier' ? 'Test Courier' : 'Test Broker',
          'isProfileCompleted': false,
        };

        if (selectedRole == 'courier') {
          userData.addAll({
            'courierID': uid,
            'baseLocationLat': 0.0,
            'baseLocationLong': 0.0,
            'currentLocationLat': 0.0,
            'currentLocationLong': 0.0,
          });
        } else {
          userData['brokerID'] = uid;
          userData['isOnline'] = false;
        }

        await userDocRef.set(userData);
        print("📝 New $selectedRole record created.");

        // Fetch newly created user doc and return it
        DocumentSnapshot newUserDoc = await userDocRef.get();
        return newUserDoc.data() as Map<String, dynamic>? ?? {};
      }

      return {'error': "User data not found"};
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
      barrierColor: Colors.black.withOpacity(0.5), // Dim background
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink(); // Required placeholder
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, color: Colors.redAccent, size: 50),
                    const SizedBox(height: 16),
                    const Text(
                      "Account Deactivate",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Your account is not active.\nPlease contact support +923065000660.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Ok"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: IntrinsicWidth(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: _selectedToggle,
                  onPressed: (int index) {
                    setState(() {
                      _selectedIndex = index;
                      _selectedToggle[index] = true;
                      _selectedToggle[1 - index] = false;
                      if (_selectedIndex == 0) {
                        _emailController.text = '';
                      } else {
                        _emailController.text = '';
                      }
                    });
                  },
/*    _emailController.text = 'broker@gmail.com';
    } else {
  _emailController.text = 'courier@gmail.com';*/
                  borderRadius: BorderRadius.circular(10),
                  selectedBorderColor: Colors.grey,
                  selectedColor: Colors.white,
                  fillColor: Palette.primaryColor,
                  color: Colors.black,
                  constraints:
                      const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
                  children: _toggleText.map((text) => Text(text)).toList(),
                ),
                const SizedBox(height: 20.0),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: emailHint,
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return Validator.validateEmail(email: value ?? '');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                PasswordField(controller: _passwordController),
                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: (newValue) {
                    setState(() {
                      _rememberMe = newValue ?? false;
                    });
                  },
                  title: const Text("Remember Me"),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,

                  // ✅ Custom colors
                  activeColor: Colors.green,      // Checkbox fill color when checked
                  checkColor: Colors.white,       // Tick icon color
                ),


                MaterialButton(
                  onPressed: _submitForm,
                  color: Colors.blue,
                  textColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const SizedBox(
                      width: 250, child: Center(child: Text('Login'))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
