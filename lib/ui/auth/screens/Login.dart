import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/utils/dialog_utils.dart';
import 'package:broker_flutter_pp/ui/common/utils/validator.dart';
import '../../common/screens/DrawerScreen.dart';
import '../../common/utils/RoleProvider.dart';

class LoginCard extends StatelessWidget {
  const LoginCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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

class _CardViewState extends State<CardView> {
  final TextEditingController _emailController = TextEditingController(text: 'broker@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: '123456');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _selectedIndex = 0;

  String get emailHint =>
      _selectedIndex == 0 ? 'Enter Broker Email' : 'Enter Courier Email';

  final List<bool> _selectedToggle = [true, false];
  final List<String> _toggleText = ["Broker", "Courier"];

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      showProgressDialog(context);
      try {
        final auth = FirebaseAuth.instance;
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Get role from selected index
        final roleProvider = Provider.of<RoleProvider>(context, listen: false);
        final role = _selectedIndex == 0 ? UserRole.broker : UserRole.courier;
        roleProvider.setRole(role);

        // Store user info in Firestore based on role
        final firestore = FirebaseFirestore.instance;
        final collectionName = _selectedIndex == 0 ? 'broker' : 'courier';
        final user = userCredential.user;

        if (user != null) {
          await firestore.collection(collectionName).doc(user.uid).set({
            'email': user.email,
            'uid': user.uid,
          });
        }

        hideProgressDialog(context);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DrawerScreen(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        hideProgressDialog(context);

        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found for that email.';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password provided for that user.';
            break;
          default:
            errorMessage = 'Login failed: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (error) {
        hideProgressDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $error')),
        );
      }
    }
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
                      if (_selectedIndex==0) {
                        _emailController.text='broker@gmail.com';
                      } else{
                        _emailController.text='courier@gmail.com';
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  selectedBorderColor: Colors.grey,
                  selectedColor: Colors.white,
                  fillColor: Palette.primaryColor,
                  color: Colors.black,
                  constraints: const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
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
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Enter Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return Validator.validatePassword(password: value ?? '');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                MaterialButton(
                  onPressed: _submitForm,
                  color: Colors.blue,
                  textColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const SizedBox(
                      width: 250,
                      child: Center(child: Text('Login'))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
