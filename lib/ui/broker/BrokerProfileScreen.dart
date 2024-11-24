import 'package:broker_flutter_pp/ui/broker/data/BrokerProfileData.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../common/utils/RoleProvider.dart';

class BrokerProfileScreen extends StatefulWidget {
  final BrokerProfileData profile;

  const BrokerProfileScreen({super.key, required this.profile});

  @override
  _BrokerProfileScreenState createState() => _BrokerProfileScreenState();
}

class _BrokerProfileScreenState extends State<BrokerProfileScreen> {
  List<TextEditingController> _licenseControllers = [];
  final TextEditingController _paymentTermsController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();



  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.name;
    _websiteController.text = widget.profile.website;
    _countryController.text = widget.profile.country;
    _paymentTermsController.text = widget.profile.paymentTerms;

    _licenseControllers = widget.profile.license.map((license) => TextEditingController(text: license)).toList();
  }


  @override
  void dispose() {
    for (var controller in _licenseControllers) {
      controller.dispose();
    }
    _paymentTermsController.dispose();
    super.dispose();
  }

  // Ensure user is authenticated
  Future<User> _ensureAuthenticated() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      user = (await FirebaseAuth.instance.signInAnonymously()).user;
    }
    return user!;
  }

  Future<void> _saveProfile() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final updatedLicenses = _licenseControllers.map((c) => c.text).toList();

    final updatedProfile = BrokerProfileData(
      id: widget.profile.id,
      name: _nameController.text,
      website: _websiteController.text,
      country: _countryController.text,
      license: updatedLicenses,
      email: widget.profile.email,
      paymentTerms: _paymentTermsController.text,
    );

    // Save to Firestore
    await firestore.collection('broker').add(updatedProfile.toMap());

    // Update profile in RoleProvider
    Provider.of<RoleProvider>(context, listen: false).updateProfile(updatedProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving profile: $e')),
    );
  }
}


  void _addLicenseField() {
    setState(() {
      _licenseControllers.add(TextEditingController());
    });
  }

  void _removeLicenseField(int index) {
    setState(() {
      _licenseControllers.removeAt(index);
      if (_licenseControllers.isEmpty) {
        _addLicenseField();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Broker Profile'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/avatar.png'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {},
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildProfileField('ID', widget.profile.id),
                const SizedBox(height: 10),
                _buildEditableField('Name', _nameController),
                const SizedBox(height: 10),
                _buildNonEditableField('Email', widget.profile.email),
                const SizedBox(height: 10),
                _buildEditableField('Website', _websiteController),
                const SizedBox(height: 10),
                _buildEditableField('Country', _countryController),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: _buildEditableField('Payment Terms', _paymentTermsController),
                ),
                const SizedBox(height: 10),
                _buildLicenseCard(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for each profile field
  Widget _buildProfileField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonEditableField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                hintText: 'Enter $label',
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Licenses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _licenseControllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _licenseControllers[i],
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'Enter License',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeLicenseField(i),
                  ),
                ],
              ),
            ),
          TextButton(
            onPressed: _addLicenseField,
            child: const Text('Add License'),
          ),
        ],
      ),
    );
  }
}
