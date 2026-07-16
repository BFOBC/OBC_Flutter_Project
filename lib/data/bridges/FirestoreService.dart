import 'dart:async';
import 'dart:ffi';

import 'package:broker_flutter_pp/ui/broker/model/BrokerProfileData.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:broker_flutter_pp/ui/common/models/Milestone.dart';
import 'package:broker_flutter_pp/ui/common/models/Rating.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:broker_flutter_pp/ui/courier/models/CourierLocationStatus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class FirestoreService {
  final BuildContext context;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isDialogShown = false;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  FirestoreService(this.context) {
    _monitorConnectivity();
  }
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  /// Check internet connection
  Future<bool> _isConnected2(BuildContext context) async {
    var connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No internet connection. Please check your network.')),
      );
      return false;
    }
    return true;
  }
  // Method to check internet connectivity
  Future<bool> _isConnected() async {
    var result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
// Monitor internet connectivity (WiFi & Mobile Data)
  void _monitorConnectivity() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
          print("onConnectivityChanged: $result");

          if (result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile) {
            print("✅ Internet Connected");

            // Agar dialog open hai to close karo
            if (_isDialogShown) {
              Navigator.of(context, rootNavigator: true).pop();
              _isDialogShown = false;
            }
          } else if (result == ConnectivityResult.none) {
            print("🚨 No Internet Connection");
            _showNoInternetDialog();
          }
        });
  }
// Show alert dialog when no internet
  void _showNoInternetDialog() {
    if (_isDialogShown) return; // prevent duplicate dialogs

    _isDialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false, // tap outside se dismiss na ho
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // 🔒 back press disable
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.wifi_off, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text("No Internet", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              "Please connect to WiFi or Mobile Data.\n\n"
                  "This dialog will close automatically once internet is back.",
              style: TextStyle(fontSize: 14),
            ),
          ),
        );
      },
    );
  }



  // Dispose listener when not needed
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> saveBrokerProfile({
    required bool isProfileCompleted,
    required String userId,
    required String email,
    required String countryCode,
    required String? profilePictureUrl,
    required TextEditingController nameController,
    required TextEditingController websiteController,
    required TextEditingController companyNameController,
    required TextEditingController countryController,
    required String phoneNumberController,
    required TextEditingController paymentTermsController,
    required List<TextEditingController> licenseControllers,
  }) async {
    try {
      final updatedLicenses = licenseControllers.map((c) => c.text).toList();

      DocumentReference userDoc = _firestore.collection('broker').doc(userId);

      Map<String, dynamic> newData = {
        'name': nameController.text.isEmpty ? 'N/A' : nameController.text,
        'website': websiteController.text.isEmpty ? 'N/A' : websiteController.text,
        'company': companyNameController.text.isEmpty ? 'N/A' : companyNameController.text,
        'country': countryController.text.isEmpty ? 'N/A' : countryController.text,
        'phoneNumber': phoneNumberController.isEmpty ? 'N/A' : phoneNumberController.trim(),
        'paymentTerms': paymentTermsController.text.isEmpty ? 'N/A' : paymentTermsController.text,
        'license': updatedLicenses,
        'email': email,
        'countryCode': countryCode,
        'profilePictureUrl': profilePictureUrl,
        'isProfileCompleted': isProfileCompleted,
      };

      await userDoc.set(newData, SetOptions(merge: true));

      Fluttertoast.showToast(
        msg: "✅ Profile saved successfully!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  Future<void> updateLegIDS(String emptyLegRequestID,
      List<String> milestoneNodeID) async {
    try {
      // Reference to the milestones collection
      CollectionReference milestones = _firestore.collection('milestones');

      // Iterate over each milestoneNodeID in the list
      for (String milestoneID in milestoneNodeID) {
        // Update the emptyLegRequestID field in the milestone document
        await milestones.doc(milestoneID).update({
          'emptyLegRequestID': emptyLegRequestID,
        });

        print('Updated emptyLegRequestID in milestone: $milestoneID');
      }
    } catch (e) {
      print('Error updating emptyLegRequestID: $e');
    }
  }

  Future<String?> saveEmptyLegRequest(EmptyLegRequest request, List<String> milestone) async {
    try {
      // Reference to the collection
      CollectionReference requests = _firestore.collection('emptyLegRequests');

      // Create a new document with an auto-generated ID
      DocumentReference docRef = requests.doc();

      // Assign ID to the request model
      request.emptyLegRequestID = docRef.id;

      // Optional: Convert to UTC if needed
      // request.startTimeDate = convertToUTCFromCustomFormat(request.startTimeDate.toString());
      // request.endTimeDate = convertToUTCFromCustomFormat(request.endTimeDate.toString());

      // Create a notification
      String msg = "Broker sent you New Job request ${_currentUser?.email}";
      createNotification(
        brokerID: request.brokerID,
        courierID: request.courierID,
        emptyLegRequestID: request.emptyLegRequestID!,
        sentBy: "Broker",
        message: msg,
      );

      // Save the request to Firestore
      await docRef.set(request.toJson());

      // Update milestone IDs
      updateLegIDS(request.emptyLegRequestID!, milestone);

      print('Request saved with nodeID: ${request.emptyLegRequestID}');

      // ✅ Return the generated ID
      return request.emptyLegRequestID;
    } catch (e) {
      print('Error saving request: $e');
      return null; // In case of error
    }
  }

  Future<List<Milestone>> getMilestonesByEmptyLegRequestID(
      String emptyLegRequestID) async {
    try {
      // Reference to the milestones collection
      CollectionReference milestones = _firestore.collection('milestones');

      // Query to filter the milestones based on the emptyLegRequestID
      QuerySnapshot snapshot = await milestones
          .where('emptyLegRequestID', isEqualTo: emptyLegRequestID)
          .get();

      // Map each document snapshot to a Milestone object
      List<Milestone> milestoneList = snapshot.docs.map((doc) {
        // Convert the document data into a map
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Convert the map into a Milestone object
        return Milestone.fromMap(data);
      }).toList();

      print('Successfully fetched ${milestoneList
          .length} milestones with emptyLegRequestID: $emptyLegRequestID');
      return milestoneList;
    } catch (e) {
      print('Error fetching milestones: $e');
      return [];
    }
  }

  // Method to fetch data from the emptyLegRequests collection
  Future<List<EmptyLegRequest>> getEmptyLegRequests({required String courierID}) async {
    try {
      print('➡️ Fetching EmptyLegRequests for courierID: $courierID');

      Query query = _firestore.collection('emptyLegRequests')
          .where('status', isEqualTo: 'pending')
          .where('courierID', isEqualTo: courierID);

      print('🔎 Running Firestore query: $query');

      QuerySnapshot querySnapshot = await query.get();
      print('✅ Query executed. Total docs returned: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        print('⚠️ No documents found for courierID: $courierID with status=pending');
        return [];
      }

      List<EmptyLegRequest> requestsList = [];

      for (var i = 0; i < querySnapshot.docs.length; i++) {
        var doc = querySnapshot.docs[i];
        print('\n--- Document #${i + 1} ---');
        print('Doc ID: ${doc.id}');

        final rawData = doc.data();
        print('Raw data type: ${rawData.runtimeType}');
        print('Raw data content: $rawData');

        if (rawData == null) {
          print('⚠️ doc.data() is null for doc id: ${doc.id} — skipping');
          continue;
        }

        // Try cast safely
        Map<String, dynamic>? mapData;
        try {
          mapData = (rawData as Map<String, dynamic>);
        } catch (castErr) {
          print('❌ Failed to cast doc.data() to Map<String, dynamic> for doc ${doc.id}: $castErr');
          continue;
        }

        // Optional: inspect important fields before mapping
        print('-> status: ${mapData['status']} (${mapData['status']?.runtimeType})');
        print('-> courierID: ${mapData['courierID']} (${mapData['courierID']?.runtimeType})');
        print('-> brokerID: ${mapData['brokerID']} (${mapData['brokerID']?.runtimeType})');
        print('-> milestoneNodeIDs: ${mapData['milestoneNodeIDs']} (${mapData['milestoneNodeIDs']?.runtimeType})');

        // Convert to model with try/catch so one bad doc doesn't crash all
        try {
          final request = EmptyLegRequest.fromMap(mapData);
          print('✔️ Mapped EmptyLegRequest: emptyLegRequestID=${request.emptyLegRequestID}, brokerID=${request.brokerID}, courierID=${request.courierID}, status=${request.status}, milestoneCount=${request.milestoneNodeIDs.length}');
          requestsList.add(request);
        } catch (mapErr, mapStack) {
          print('❌ Error mapping doc ${doc.id} to EmptyLegRequest: $mapErr');
          print(mapStack);
          // Continue with next doc
        }
      }

      print('\n🔚 Completed mapping. Total mapped requests: ${requestsList.length}');
      return requestsList;
    } catch (e, stack) {
      print('🔥 Error fetching empty leg requests: $e');
      print(stack);
      return [];
    }
  }


  // Method to fetch brokers by brokerIDs using the BrokerProfileData model
  Future<List<BrokerProfileData>> getBrokersByBrokerID(
      List<String> brokerIDs) async {
    try { 
      // Reference to the broker collection
      CollectionReference brokers = _firestore.collection('broker');
      List<BrokerProfileData> brokersList = [];

      // Break brokerIDs into chunks of 10 to avoid Firestore's `whereIn` limit
      final chunkedBrokerIDs = chunkList(brokerIDs, 10);

      for (List<String> chunk in chunkedBrokerIDs) {
        QuerySnapshot querySnapshot = await brokers
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        brokersList.addAll(querySnapshot.docs.map((doc) {
          return BrokerProfileData.fromMap(
              doc.id, doc.data() as Map<String, dynamic>);
        }));
      }

      print('Fetched brokers: ${brokersList.length}');
      return brokersList;
    } catch (e) {
      print('Error fetching brokers: $e');
      return [];
    }
  }

  List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
          i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }


  // Method to fetch emptyLegRequests and associated brokers
  Future<List<Map<String, dynamic>>> getEmptyLegRequestsWithBrokers(String ID) async {
    try {
      // Get all the empty leg requests
      List<EmptyLegRequest> requests = await getEmptyLegRequests(courierID: ID);

      // Get all unique brokerIDs from the emptyLegRequests
      List<String> brokerIDs = requests
          .map((request) => request.brokerID)
          .toSet() // Remove duplicates
          .toList();

      print("getEmptyLegRequestsWithBrokers is called...");
      print(brokerIDs.toString());

      // Fetch brokers for the obtained brokerIDs
      List<BrokerProfileData> brokers = await getBrokersByBrokerID(brokerIDs);
      print("getBrokersByBrokerID is called");
      print(brokers.toString());

      // Combine both the requests and brokers data
      List<Map<String, dynamic>> combinedData = [];
      for (var request in requests) {
        Map<String, dynamic> requestData = request.toJson();

        // Find the broker data for each request
        BrokerProfileData? brokerData = brokers.firstWhere(
              (broker) => broker.brokerID == request.brokerID,
          orElse: () =>
              BrokerProfileData(
                brokerID: 'Not found',
                name: 'Unknown',
                contact: 'N/A',
                rating: 0,
                website: 'N/A',
                company: 'N/A',
                country: 'N/A',
                phoneNumber: 'N/A',
                license: [],
                email: 'N/A',
                paymentTerms: 'N/A',
                profilePictureUrl: null,
              ),
        );

        // Add broker information to request data
        requestData['broker'] = brokerData.toMap();

        combinedData.add(requestData);
      }

      return combinedData;
    } catch (e) {
      print('Error fetching empty leg requests with brokers: $e');
      return [];
    }
  }

  Future<List<BrokerProfileData>> fetchBrokerProfile(String brokerID) async {
    try {
      print('Broker brokerID');
      print(brokerID);
      // Query Firestore for the specific broker using the brokerID
      DocumentSnapshot brokerDoc = await FirebaseFirestore.instance
          .collection('broker')
          .doc(brokerID)
          .get();

      if (brokerDoc.exists) {
        // Parse and return the data as a list of one BrokerProfileData instance
        return [
          BrokerProfileData.fromMap(
            brokerID,
            brokerDoc.data() as Map<String, dynamic>,
          ),
        ];
      } else {
        // Return an empty list if no data exists for the provided brokerID
        return [];
      }
    } catch (e) {
      print('Error fetching broker details: $e');
      // Return an empty list in case of an error
      return [];
    }
  }
  Future<BrokerProfileData?> fetchBrokerProfile2(String brokerID) async {
    try {
      print('Fetching broker profile for ID: $brokerID');

      // Fetch broker document from Firestore
      DocumentSnapshot brokerDoc = await FirebaseFirestore.instance
          .collection('broker')
          .doc(brokerID)
          .get();

      if (!brokerDoc.exists || brokerDoc.data() == null) {
        print('No broker found for ID: $brokerID');
        return null;
      }

      // Convert broker details
      BrokerProfileData brokerProfile = BrokerProfileData.fromMap(
        brokerID,
        brokerDoc.data() as Map<String, dynamic>,
      );

      // Fetch ratings from broker -> brokerID -> rating collection
      QuerySnapshot ratingsSnapshot = await FirebaseFirestore.instance
          .collection('broker')
          .doc(brokerID)
          .collection('rating')
          .get();

      List<Rating> ratings = ratingsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Fetched rating: $data'); // Log rating data
        return Rating.fromMap(data);
      }).toList();

      // Assign the fetched ratings to brokerProfile
      brokerProfile = BrokerProfileData(
        brokerID: brokerProfile.brokerID,
        name: brokerProfile.name,
        contact: brokerProfile.contact,
        rating: ratings.isNotEmpty
            ? ratings.map((r) => r.rating).reduce((a, b) => a + b) / ratings.length
            : 0.0, // Calculate average rating if available
        website: brokerProfile.website,
        company: brokerProfile.company,
        country: brokerProfile.country,
        phoneNumber: brokerProfile.phoneNumber,
        license: brokerProfile.license,
        email: brokerProfile.email,
        paymentTerms: brokerProfile.paymentTerms,
        profilePictureUrl: brokerProfile.profilePictureUrl,
        ratings: ratings, // Add fetched ratings
      );

      print('Final broker profile: ${brokerProfile.toMap()}'); // Log final profile
      return brokerProfile;
    } catch (e) {
      print('Error fetching broker details: $e');
      return null;
    }
  }

  // Method to get emptyLegRequest data from Firestore based on nodeID
  Future<EmptyLegRequest> getEmptyLegRequest(String nodeID) async {
    try {
      // Reference to the emptyLegRequests collection and specific document
      DocumentReference docRef = _firestore.collection('emptyLegRequests').doc(
          nodeID);

      // Fetch the document from Firestore
      DocumentSnapshot snapshot = await docRef.get();
      print('emptyLegRequestID$nodeID');
      print(nodeID);

      // Check if the document exists
      if (snapshot.exists) {
        // Convert the Firestore document data into an EmptyLegRequest object
        var data = snapshot.data() as Map<String, dynamic>;
        return EmptyLegRequest.fromMap(data);
      } else {
        print('No data found for nodeID: $nodeID');
        throw Exception('No data found');
      }
    } catch (e) {
      print('Error fetching emptyLegRequest: $e');
      throw Exception('Error fetching emptyLegRequest');
    }
  }


  // Method to update status in emptyLegRequests collection for a specific nodeID
  Future<void> updateJobStatus(String nodeID, String status) async {
    try {
      // Reference to the emptyLegRequests collection and specific document
      DocumentReference docRef = _firestore.collection('emptyLegRequests').doc(
          nodeID);
      // Update the 'status' field
      await docRef.update({
        'status': status, // Field name 'status' and its new value
      });
      print('Status updated successfully');
    } catch (e) {
      print('Error updating status: $e');
      throw Exception(
          'Error updating status: $e'); // Throwing an exception if error occurs
    }
  }
  Future<void> updateEmptyLegTableJobStatus(String nodeID, String status) async {
    try {
      // Reference to the emptyLegRequests collection and specific document
      DocumentReference docRef = _firestore.collection('emptyLegs').doc(
          nodeID);
      // Update the 'status' field
      await docRef.update({
        'status': status, // Field name 'status' and its new value
      });
      print('emptyLegs Status updated successfully');
    } catch (e) {
      print('Error updating status: $e');
      throw Exception(
          'Error updating status: $e'); // Throwing an exception if error occurs
    }
  }
  Future<void> updateMilestoneStatus(String nodeID, String status) async {
    try {
      // Reference to the emptyLegRequests collection and specific document
      DocumentReference docRef = _firestore.collection('milestones').doc(
          nodeID);
      // Update the 'status' field
      await docRef.update({
        'milestoneStatus': status, // Field name 'status' and its new value
      });
      print('Status updated successfully');
    } catch (e) {
      print('Error updating status: $e');
      throw Exception(
          'Error updating status: $e'); // Throwing an exception if error occurs
    }
  }

  Future<void> createNotification({
    String brokerID = '', // Default value is an empty string
    String courierID = '', // Default value is an empty string
    String emptyLegRequestID = '', // Default value is an empty string
    String sentBy = '', // Default value is an empty string
    String milestoneID = '', // Default value is an empty string
    String message = '', // Default value is an empty string
  }) async {
    try {
      // Reference to the notification collection
      CollectionReference notifications = _firestore.collection('notification');

      // Generate a new nodeID using Firestore's auto-ID generator
      String nodeID = notifications
          .doc()
          .id;

      // Prepare the data to be saved
      Map<String, dynamic> notificationData = {
        'notificationID': nodeID,
        'emptyLegRequestID': emptyLegRequestID.isNotEmpty
            ? emptyLegRequestID
            : 'N/A',
        // Default to 'N/A' if empty
        'brokerID': brokerID.isNotEmpty ? brokerID : 'N/A',
        // Default to 'N/A' if empty
        'courierID': courierID.isNotEmpty ? courierID : 'N/A',
        // Default to 'N/A' if empty
        'sentBy': sentBy.isNotEmpty ? sentBy : 'Unknown',
        // Default to 'Unknown' if empty
        'message': message.isNotEmpty ? message : 'No message',
        // Default to 'No message provided' if empty
        'milestoneID': milestoneID.isNotEmpty ? milestoneID : 'N/A',
        // Default to 'N/A' if empty
        'currentDateTime': DateTime.now().toUtc().toIso8601String(),
        // UTC format
      };

      // Save the data under the generated nodeID
      await notifications.doc(nodeID).set(notificationData);

      print('Notification saved successfully with nodeID: $nodeID');
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> readNotifications(String role) async {
    try {
      CollectionReference notifications = _firestore.collection('notification');

      Query query;

      if (role == 'Courier') {
        query = notifications.where('courierID', isEqualTo: _currentUser?.uid);
      } else {
        query = notifications.where('brokerID', isEqualTo: _currentUser?.uid);
      }

      QuerySnapshot querySnapshot = await query.get();

      List<Map<String, dynamic>> notificationsList = querySnapshot.docs
          .map((doc) => {
        'notificationID': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();

      print('Notifications retrieved: ${notificationsList.length}');
      return notificationsList;
    } catch (e) {
      print('Error reading notifications: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> readFAQs(String role) async {
    try {
      // Get the document for the specific role (broker/courier)
      DocumentSnapshot roleDoc =
      await _firestore.collection('faqs').doc(role.toLowerCase()).get();

      // Get the general FAQs as well (common to both)
      DocumentSnapshot generalDoc =
      await _firestore.collection('faqs').doc('general').get();

      List<Map<String, dynamic>> faqList = [];

      // Add general FAQs if available
      if (generalDoc.exists) {
        final generalData = generalDoc.data() as Map<String, dynamic>;
        final generalQuestions =
        List<Map<String, dynamic>>.from(generalData['questions'] ?? []);
        faqList.addAll(generalQuestions);
      }

      // Add role-specific FAQs if available
      if (roleDoc.exists) {
        final roleData = roleDoc.data() as Map<String, dynamic>;
        final roleQuestions =
        List<Map<String, dynamic>>.from(roleData['questions'] ?? []);
        faqList.addAll(roleQuestions);
      }

      print('✅ FAQs retrieved for $role: ${faqList.length}');
      return faqList;
    } catch (e) {
      print('❌ Error reading FAQs: $e');
      return [];
    }
  }

  // Method to delete a notification by its ID
  Future<void> deleteNotification(String notificationID) async {
    try {
      // Reference to the notification collection
      CollectionReference notifications = _firestore.collection('notification');

      // Delete the document with the given notificationID
      await notifications.doc(notificationID).delete();

      print('Notification with ID: $notificationID deleted successfully');
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<String> getBrokerName(String brokerID) async {
    try {
      // Reference to the broker document with only the 'name' field selected
      DocumentSnapshot<Map<String, dynamic>> brokerDoc =
      await _firestore.collection('broker').doc(brokerID).get(
          const GetOptions(source: Source.server));

      // Check if the document exists
      if (brokerDoc.exists) {
        // Retrieve and return the broker name
        return brokerDoc.data()?['name'] ?? 'Unknown';
      } else {
        return 'Broker Not Found';
      }
    } catch (e) {
      print('Error fetching broker name: $e');
      return 'Error Fetching Name';
    }
  }

  Future<String> getCourierName(String brokerID) async {
    try {
      // Reference to the broker document with only the 'name' field selected
      DocumentSnapshot<Map<String, dynamic>> brokerDoc =
      await _firestore.collection('courier').doc(brokerID).get(
          const GetOptions(source: Source.server));

      // Check if the document exists
      if (brokerDoc.exists) {
        // Retrieve and return the broker name
        return brokerDoc.data()?['name'] ?? 'Unknown';
      } else {
        return 'Broker Not Found';
      }
    } catch (e) {
      print('Error fetching broker name: $e');
      return 'Error Fetching Name';
    }
  }

  Future<List<Map<String, dynamic>>> getJobsByCourierID() async {
    try {
      final querySnapshot = await _firestore
          .collection('emptyLegRequests')
          .where('courierID', isEqualTo: _currentUser?.uid)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error fetching jobs: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getJobsWithMilestones() async {
    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);

      String filterField;
      String filterValue = _currentUser!.uid;

      if (roleProvider.role == UserRole.courier) {
        filterField = 'courierID';
      } else if (roleProvider.role == UserRole.broker) {
        filterField = 'brokerID';
      } else {
        debugPrint("Unknown role, returning empty list.");
        return [];
      }

      debugPrint("Fetching jobs for $filterField: $filterValue");

      final querySnapshot = await _firestore
          .collection('emptyLegRequests')
          .where(filterField, isEqualTo: filterValue)
          .get();

      debugPrint("Total jobs fetched: ${querySnapshot.docs.length}");

      final List<Map<String, dynamic>> jobsWithMilestones = [];

      for (var jobDoc in querySnapshot.docs) {
        final jobData = jobDoc.data();
        final List<dynamic>? milestoneNodeIDs = jobData['milestoneNodeIDs'];

        debugPrint("Processing job with ID: ${jobDoc.id}");

        if (milestoneNodeIDs != null && milestoneNodeIDs.isNotEmpty) {
          debugPrint("Found milestoneNodeIDs: $milestoneNodeIDs");

          final List<Map<String, dynamic>> allMilestones = [];
          for (var milestoneNodeID in milestoneNodeIDs) {
            final milestones = await getMilestoneByNodeID(milestoneNodeID);

            if (milestones != null) {
              debugPrint(
                  "Found milestones for NodeID $milestoneNodeID: $milestones");
              allMilestones.add(milestones);
            } else {
              debugPrint("No milestones found for NodeID $milestoneNodeID");
              allMilestones.add({});
            }
          }

          jobData['milestones'] = allMilestones;
        } else {
          debugPrint("No milestoneNodeIDs found for job: ${jobDoc.id}");
          jobData['milestones'] = [];
        }

        jobsWithMilestones.add(jobData);
      }

      debugPrint("Combined Jobs with Milestones: $jobsWithMilestones");
      return jobsWithMilestones;
    } catch (e) {
      debugPrint("Error fetching jobs with milestones: $e");
      return [];
    }
  }


  Future<Map<String, dynamic>?> getMilestoneByNodeID(
      String milestoneNodeID) async {
    try {
      debugPrint("Fetching milestone for Node ID: $milestoneNodeID");

      final querySnapshot = await _firestore
          .collection('milestones')
          .doc(milestoneNodeID)
          .get();

      if (querySnapshot.exists) {
        debugPrint(
            "Milestone found for Node ID $milestoneNodeID: ${querySnapshot
                .data()}");
        return querySnapshot.data();
      } else {
        debugPrint("No milestone found for Node ID: $milestoneNodeID");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching milestone for Node ID $milestoneNodeID: $e");
      return null;
    }
  }

  Future<List<Milestone>> getMilestonesByEmptyLegCourierID(
      String emptyLegCourierID) async {
    try {
      // Query the milestones collection for documents where emptyLegRequestID matches the provided value
      final querySnapshot = await _firestore
          .collection('milestones')
          .where('emptyLegRequestID', isEqualTo: emptyLegCourierID)
          .get();

      // Convert the querySnapshot to a list of Milestone objects
      final milestones = querySnapshot.docs.map((doc) {
        return Milestone.fromMap(doc.data());
      }).toList();

      return milestones;
    } catch (e) {
      print('Error getting milestones: $e');
      return [];
    }
  }

  Future<void> addRating(Rating rating) async {
    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      String collectionName = roleProvider.role == UserRole.broker ? 'courier' : 'broker';

      // Logged-in user's ID
      String userID = _currentUser!.uid;

      // If broker is logged in, they rate a courier (assign courierID)
      if (roleProvider.role == UserRole.broker) {
        rating.brokerID = userID;  // Logged-in user is the broker
      }
      // If courier is logged in, they rate a broker (assign brokerID)
      else {
        rating.courierID = userID;  // Logged-in user is the courier
      }

      // Reference to the correct Firestore path (rating stored under recipient’s ID)
      DocumentReference ratingRef = _firestore
          .collection(collectionName)  // Store under 'courier' or 'broker' collection
          .doc(rating.brokerID ?? rating.courierID)  // The person being rated (receiver)
          .collection('rating')  // Sub-collection for ratings
          .doc();  // Auto-generate rating ID

      // Assign auto-generated ratingID
      rating.ratingID = ratingRef.id;

      // Store rating data
      await ratingRef.set(rating.toMap());

      print('Rating stored successfully under $collectionName -> ${rating.brokerID ?? rating.courierID} -> rating -> ${rating.ratingID}');
    } catch (e) {
      print('Error storing rating: $e');
      throw Exception('Error storing rating: $e');
    }
  }

  // Method to update status in emptyLegRequests collection for a specific nodeID
  Future<void> updateRatingFlag(String nodeID, String keyName,String value) async {
    try {
      // Reference to the emptyLegRequests collection and specific document
      DocumentReference docRef = _firestore.collection('emptyLegRequests').doc(
          nodeID);
      // Update the 'status' field
      await docRef.update({
        keyName: value, // Field name 'status' and its new value
      });
      print('Status updated successfully');
    } catch (e) {
      print('Error updating status: $e');
      throw Exception(
          'Error updating status: $e'); // Throwing an exception if error occurs
    }
  }
  Future<String?> signInAndSaveUser(String email, String password, int selectedIndex) async {
    // Check internet before proceeding
    if (!await _isConnected()) {
      return 'No internet connection. Please check your network.';
    }
    try {
      final _auth = FirebaseAuth.instance;

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        String collectionName = selectedIndex == 0 ? 'broker' : 'courier';
        DocumentReference userRef = _firestore.collection(collectionName).doc(user.uid);

        // Check if user document exists
        DocumentSnapshot userDoc = await userRef.get();

        if (userDoc.exists) {
          // Update existing user
          await userRef.update({
            'email': user.email,
            'uid': user.uid,
          });
        } else {
          // Create new user entry
          await userRef.set({
            'email': user.email,
            'uid': user.uid,
            // You can add more fields here
          });
        }
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided for that user.';
        default:
          return 'Login failed: Invalid Credentials';
      }
    } catch (error) {
      return 'Login failed: $error';
    }
  }
  Future<Map<String, double>> getCourierLocation(String courierID) async {
    try {
      // Get courier document
      DocumentSnapshot<Map<String, dynamic>> courierDoc = await FirebaseFirestore
          .instance
          .collection('courier')
          .doc(courierID)
          .get(const GetOptions(source: Source.server));

      if (!courierDoc.exists) {
        print('Courier not found');
        return {};
      }

      final data = courierDoc.data();
      final bool isCurrent = data?['current'] ?? true;

      if (isCurrent) {
        return {
          'lat': data?['currentLocationLat']?.toDouble() ?? 0,
          'long': data?['currentLocationLong']?.toDouble() ?? 0,
        };
      } else {
        return {
          'lat': data?['baseLocationLat']?.toDouble() ?? 0,
          'long': data?['baseLocationLong']?.toDouble() ?? 0,
        };
      }
    } catch (e) {
      print('Error fetching courier location: $e');
      return {};
    }
  }
  Future<CourierLocationStatus?> getCourierLocationStatus(String courierID) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> courierDoc = await FirebaseFirestore
          .instance
          .collection('courier')
          .doc(courierID)
          .get(const GetOptions(source: Source.server));

      if (!courierDoc.exists) {
        print('Courier document not found');
        return null;
      }

      final data = courierDoc.data();
      bool isCurrent = data?['current'] ?? false;
      String country = data?['country'] ?? 'Unknown';

      return CourierLocationStatus(isCurrent: isCurrent, country: country);
    } catch (e) {
      print('Error fetching courier location status: $e');
      return null;
    }
  }
/// Update user's online status to false (offline)
  Future<void> setUserOffline() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint("⚠️ No logged-in user found. Cannot set offline.");
        return;
      }

      // 🔹 Determine user collection based on role
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      final collectionName =
      roleProvider.role == UserRole.broker ? 'broker' : 'courier';
      final docRef = _firestore.collection(collectionName).doc(currentUser.uid);

      // 🔹 Prepare update data
      final updateData = {
        "isOnline": false,
        "lastSeen": FieldValue.serverTimestamp(),
      };

      // 🔹 Step 1: Update status first
      try {
        await docRef.update(updateData);
        debugPrint("✅ User offline + lastSeen updated in '$collectionName'");
      } catch (e) {
        debugPrint("⚠️ Doc not found, using set(merge:true)");
        await docRef.set(updateData, SetOptions(merge: true));
        debugPrint("✅ User offline + lastSeen field added in '$collectionName'");
      }

      // 🔹 Step 2: Clear FCM token (delete or empty)
      try {
        await docRef.update({
          "fcm_token": FieldValue.delete(),
        });
        debugPrint("✅ FCM token DELETED successfully.");
      } catch (e) {
        debugPrint("⚠️ FCM delete failed, setting empty instead: $e");
        await docRef.set({
          "fcm_token": "",
        }, SetOptions(merge: true));
        debugPrint("✅ FCM token set to empty string instead.");
      }

      // 🔹 Step 3: Finally sign out
      await FirebaseAuth.instance.signOut();
      debugPrint("🚪 User signed out successfully.");
    } catch (e) {
      debugPrint("❌ Error in setUserOffline: $e");
    }
  }

  /// Mark user as online
  Future<void> setUserOnline() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint("⚠️ No logged-in user found. Cannot set online.");
        return;
      }

      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      String collectionName = (roleProvider.role == UserRole.broker)
          ? 'broker'
          : 'courier';

      final docRef = _firestore.collection(collectionName).doc(currentUser.uid);

      final updateData = {
        "isOnline": true
      };

      try {
        await docRef.update(updateData);
        debugPrint("✅ User set online in '$collectionName'");
      } catch (e) {
        await docRef.set(updateData, SetOptions(merge: true));
        debugPrint("✅ User online + lastSeen created in '$collectionName'");
      }
    } catch (e) {
      debugPrint("❌ Error in setUserOnline: $e");
    }
  }
   Future<String?> getCourierProfilePicture(String courierID) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courier')
          .doc(courierID)
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) return null;

      final data = doc.data();
      return data?['profilePictureUrl'] as String?;
    } catch (e) {
      print('❌ Error fetching courier profile picture: $e');
      return null;
    }
  }

   Future<String?> getBrokerProfilePicture(String brokerID) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('broker')
          .doc(brokerID)
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) return null;

      final data = doc.data();
      return data?['profilePictureUrl'] as String?;
    } catch (e) {
      print('❌ Error fetching broker profile picture: $e');
      return null;
    }
  }

}