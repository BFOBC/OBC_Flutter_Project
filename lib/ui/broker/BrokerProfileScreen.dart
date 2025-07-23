
import 'dart:convert';

import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/broker/model/BrokerProfileData.dart';
import 'package:broker_flutter_pp/ui/common/utils/toast_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:permission_handler/permission_handler.dart';


class BrokerProfileScreen extends StatefulWidget {

  final BrokerProfileData brokerProfile;

  const BrokerProfileScreen({super.key, required this.brokerProfile});
  @override
  _BrokerProfileScreenState createState() => _BrokerProfileScreenState();
}

class _BrokerProfileScreenState extends State<BrokerProfileScreen> {
  late User _currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _paymentTermsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedPhoneNumber = "";
  List<TextEditingController> _licenseControllers = [];
  String? _profilePictureUrl;
  File? _image;
  String uploadedImageUrl = "";
  bool _isUploading = false;
  @override
  void initState() {
    super.initState();
    _initializeProfile();
    print("Broker Profile name URL: ${widget.brokerProfile.name}");

  }
  Future<void> _initializeProfile() async {
    _currentUser = FirebaseAuth.instance.currentUser!;
    DocumentSnapshot profileSnapshot =
        await _firestore.collection('broker').doc(_currentUser.uid).get();

    if (profileSnapshot.exists) {
      Map<String, dynamic> data = profileSnapshot.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? 'N/A';
      _websiteController.text = data['website'] ?? 'N/A';
      _companyNameController.text = data['company'] ?? 'N/A';
      _countryController.text = data['country'] ?? 'N/A';
      _phoneController.text = data['phoneNumber'] ?? 'N/A';
      _paymentTermsController.text = data['paymentTerms'] ?? 'N/A';
      _licenseControllers = (data['license'] as List<dynamic>? ?? [])
          .map((license) => TextEditingController(text: license as String))
          .toList();
      _profilePictureUrl = data['profilePictureUrl'];
    } else {
      _licenseControllers = [TextEditingController()];
    }

    setState(() {

    });
  }
  Future<void> _saveProfile() async {
    try {
      FirestoreService firestoreService = FirestoreService(context);

      await firestoreService.saveBrokerProfile(
        userId: _currentUser.uid,
        email: _currentUser.email.toString(),
        profilePictureUrl: _profilePictureUrl,
        nameController: _nameController,
        websiteController: _websiteController,
        companyNameController: _companyNameController,
        countryController: _countryController,
        phoneNumberController: _selectedPhoneNumber,
        paymentTermsController: _paymentTermsController,
        licenseControllers: _licenseControllers,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  Future<void> pickImageAndUpload() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      showCustomToast("User not logged in", isError: true);
      return;
    }

    final status = await Permission.photos.request();
    if (!status.isGranted) {
      showCustomToast("Permission denied", isError: true);
      return;
    }

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _isUploading = true;
    });

    try {
      final url = Uri.parse("https://mopogotechnologies.com/uploadImages.php");
      final request = http.MultipartRequest('POST', url);
      request.fields['user_id'] = userId;
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final json = jsonDecode(resBody);

      if (json['status'] == 'success') {
        uploadedImageUrl = json['url'];

        print("Picked Image: ${_image?.path}");
        print("Upload URL: $uploadedImageUrl");
        print("User ID: $userId");

        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('broker').doc(userId).set(
            {'profilePictureUrl': uploadedImageUrl},
            SetOptions(merge: true),
          );
          print("Firestore update success");
        } catch (e) {
          print("Firestore error: $e");
        }

        setState(() {
          _isUploading = false;
        });

        showCustomToast("Profile updated successfully!");
      } else {
        setState(() {
          _isUploading = false;
        });
        showCustomToast(json['message'] ?? "Upload failed", isError: true);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      showCustomToast("An error occurred during upload", isError: true);
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName = 'profile_pictures/${_currentUser.uid}.jpg';
      try {
        TaskSnapshot uploadTask =
            await _storage.ref(fileName).putFile(file);
        String downloadUrl = await uploadTask.ref.getDownloadURL();

        setState(() {
          _profilePictureUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture uploaded successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading picture: $e')),
        );
      }
    }
  }

  void _removeLicenseField(int index) {
  setState(() {
    _licenseControllers.removeAt(index);
  });
}

void _addLicenseField() {
  setState(() {
    _licenseControllers.add(TextEditingController());
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broker Profile'),
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: (uploadedImageUrl?.isNotEmpty == true)
                              ? CachedNetworkImageProvider(
                            "${uploadedImageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}",
                          )
                              : (_profilePictureUrl?.isNotEmpty == true)
                              ? CachedNetworkImageProvider(
                            "${_profilePictureUrl!}?t=${DateTime.now().millisecondsSinceEpoch}",
                          )
                              : const AssetImage('assets/avatar.png') as ImageProvider,
                        ),

                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: InkWell(
                            onTap: pickImageAndUpload,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                  //  _buildProfileField('Broker ID',_currentUser.uid),
                    const SizedBox(height: 5),
                    _buildNonEditableField('Email', _currentUser.email ?? 'N/A'),
                    const SizedBox(height: 5),
                    _buildEditableField('Name', _nameController),
                    const SizedBox(height: 5),
                    _buildEditableField('Website', _websiteController),
                    const SizedBox(height: 5),
                    _buildEditableField('Company', _companyNameController),

                    const SizedBox(height: 5),
                    _buildEditableField('Country', _countryController),
                    _buildPhoneNumberField(_phoneController, (phone) {
                      setState(() {
                        _selectedPhoneNumber = phone;
                      });
                    }),
                    const SizedBox(height: 5),
                    _buildEditableField('Payment Terms', _paymentTermsController),
                    const SizedBox(height: 10),
                    _buildLicenseCard(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save'),
                    ),
                  ],
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
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField(
      TextEditingController controller, Function(String) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntlPhoneField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
        initialCountryCode: 'PK', // Default country
        onChanged: (phone) {
          onChanged(phone.completeNumber); // Callback to get full number
        },
      ),
    );
  }


  Widget _buildLicenseCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
        // Render all license input fields
        for (int i = 0; i < _licenseControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _licenseControllers[i],
                      decoration: const InputDecoration(
                        hintText: 'Enter License',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.black45),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Example: Allow letters
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeLicenseField(i),
                  ),
                ],
              ),
            ),
          ),
        // Add License button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(''), // Empty to align the button properly
              ),
              ElevatedButton(
                onPressed: _addLicenseField,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text('Add License'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

}