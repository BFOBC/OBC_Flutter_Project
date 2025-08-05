import 'dart:convert';

import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/broker/model/BrokerProfileData.dart';
import 'package:broker_flutter_pp/ui/common/models/CountryDialCode.dart';
import 'package:broker_flutter_pp/ui/common/screens/DrawerScreen.dart';
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

  String countryCode = '+49';
  String initialCountryCode = 'DE';
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
    Map<String, dynamic> data = profileSnapshot.data() as Map<String, dynamic>;

    if (profileSnapshot.exists) {
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

      String apiDialCode = data['countryCode'];

      String? isoCode = CountryDialCodeData.getIsoCode(apiDialCode);
      int? maxLength = CountryDialCodeData.getMaxLength(apiDialCode);

      print('ISO Country Code: $isoCode');
      print('Max Length: $maxLength');

      if (isoCode != null) {
        setState(() {
          initialCountryCode = isoCode;
          // You can also store maxLength and use it in validator if needed
        });
      }

    } else {
      _licenseControllers = [TextEditingController()];
    }
    final isProfileCompleted = data?['isProfileCompleted'] ?? false;

    if (!isProfileCompleted) {
      if (context.mounted) {
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                backgroundColor: Colors.white,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Incomplete Profile",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                    child: const Text("OK",
                        style: TextStyle(color: Colors.orange)),
                  ),
                ],
              );
            },
          );
        });
      }
    }

    setState(() {});
  }

  Future<void> _saveProfile() async {
    // ✅ Validation before proceeding
    final missingFields = <String>[];

    if (_nameController.text.trim().isEmpty || _nameController.text.trim() == "Test Broker") {
      missingFields.add("Name");
    }
    if (_websiteController.text.trim().isEmpty || _websiteController.text.trim() == "N/A") {
      missingFields.add("Website");
    }
    if (_companyNameController.text.trim().isEmpty  || _companyNameController.text.trim() == "N/A") {
      missingFields.add("Company Name");
    }
    if (_countryController.text.trim().isEmpty || _countryController.text.trim() == "N/A") {
      missingFields.add("Country");
    }
    if (_phoneController.text.trim().isEmpty) {
      missingFields.add("Phone Number");
    }
    if (_paymentTermsController.text.trim().isEmpty || _paymentTermsController.text.trim() == "N/A") {
      missingFields.add("Payment Terms");
    }

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in the following field(s): ${missingFields.join(", ")}'),
        ),
      );
      return;
    }

    if (_licenseControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add the license')),
      );
      return;
    }


    try {
      FirestoreService service = FirestoreService(context);

      await service.saveBrokerProfile(
        isProfileCompleted: true,
        userId: _currentUser.uid,
        email: _currentUser.email.toString(),
        countryCode:countryCode.toString(),
        profilePictureUrl: _profilePictureUrl,
        nameController: _nameController,
        websiteController: _websiteController,
        companyNameController: _companyNameController,
        countryController: _countryController,
        phoneNumberController: _selectedPhoneNumber,
        paymentTermsController: _paymentTermsController,
        licenseControllers: _licenseControllers,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DrawerScreen()),
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

    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _isUploading = true;
    });

    try {
      final url =
          Uri.parse("https://mopogotechnologies.com/api/uploadImages.php");
      final request = http.MultipartRequest('POST', url);
      request.fields['user_id'] = userId;
      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));

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

        showCustomToast("Profile Picture Updated!");
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
        TaskSnapshot uploadTask = await _storage.ref(fileName).putFile(file);
        String downloadUrl = await uploadTask.ref.getDownloadURL();

        setState(() {
          _profilePictureUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile picture uploaded successfully!')),
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
                          backgroundImage:
                              (uploadedImageUrl?.isNotEmpty == true)
                                  ? CachedNetworkImageProvider(
                                      "${uploadedImageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}",
                                    )
                                  : (_profilePictureUrl?.isNotEmpty == true)
                                      ? CachedNetworkImageProvider(
                                          "${_profilePictureUrl!}?t=${DateTime.now().millisecondsSinceEpoch}",
                                        )
                                      : const AssetImage(
                                              'assets/place_holder_man.png')
                                          as ImageProvider,
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
                    _buildNonEditableField(
                        'Email', _currentUser.email ?? 'N/A'),
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
                    _buildEditableField(
                        'Payment Terms', _paymentTermsController),
                    const SizedBox(height: 10),
                    _buildLicenseCard(),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _saveProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 120, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
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
        key: ValueKey(initialCountryCode), // ⬅️ force rebuild on change
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
        initialCountryCode: initialCountryCode, // Default country
        onChanged: (phone) {
          onChanged(phone.number); // Callback to get full number
          countryCode=phone.countryCode;
          print('countryCode$countryCode');
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]')), // Example: Allow letters
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
