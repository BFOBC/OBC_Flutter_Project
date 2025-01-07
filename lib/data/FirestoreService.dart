import 'package:broker_flutter_pp/ui/broker/model/BrokerProfileData.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final BuildContext context;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User _currentUser = FirebaseAuth.instance.currentUser!;
  FirestoreService(this.context);

  Future<void> saveBrokerProfile({
    required String userId,
    required String email,
    required String? profilePictureUrl,
    required TextEditingController nameController,
    required TextEditingController websiteController,
    required TextEditingController countryController,
    required TextEditingController paymentTermsController,
    required List<TextEditingController> licenseControllers,
  }) async {
    try {
      final updatedLicenses = licenseControllers.map((c) => c.text).toList();

      // Reference to the user document
      DocumentReference userDoc = _firestore.collection('broker').doc(userId);

      // Get the current data in Firestore
      DocumentSnapshot snapshot = await userDoc.get();

      // Prepare the new data
      Map<String, dynamic> newData = {
        'name': nameController.text.isEmpty ? 'N/A' : nameController.text,
        'website': websiteController.text.isEmpty ? 'N/A' : websiteController.text,
        'country': countryController.text.isEmpty ? 'N/A' : countryController.text,
        'paymentTerms': paymentTermsController.text.isEmpty ? 'N/A' : paymentTermsController.text,
        'license': updatedLicenses,
        'email': email,
        'profilePictureUrl': profilePictureUrl,
      };

      // Merge the new data with existing data
      if (snapshot.exists) {
        Map<String, dynamic>? existingData = snapshot.data() as Map<String, dynamic>?;
        newData.addAll(existingData ?? {});
      }

      // Save the merged data
      await userDoc.set(newData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  Future<void> saveEmptyLegRequest(EmptyLegRequest request) async {
    try {
      // Reference to the collection
      CollectionReference requests = _firestore.collection('emptyLegRequests');

      // Create a new document with an auto-generated ID
      DocumentReference docRef = requests.doc();

      // Update the nodeID dynamically
      request.emptyLegRequestID = docRef.id;

      String msg="Broker sent you New Job request  ${_currentUser.email}";
      createNotification(brokerID: request.brokerID, courierID: request.courierID, emptyLegRequestID: request.emptyLegRequestID.toString(),sentBy: "Broker", message: msg);
      // Save the request with the updated nodeID
      await docRef.set(request.toJson());
      print('Request saved with nodeID: ${request.emptyLegRequestID}');
    } catch (e) {
      print('Error saving request: $e');
    }
  }
  // Method to fetch data from the emptyLegRequests collection
  Future<List<EmptyLegRequest>> getEmptyLegRequests() async {
    try {
      CollectionReference requests = _firestore.collection('emptyLegRequests');
      QuerySnapshot querySnapshot = await requests.get();

      List<EmptyLegRequest> requestsList = querySnapshot.docs
          .map((doc) {
        print('Document data: ${doc.data()}'); // Debug: print document data
        return EmptyLegRequest.fromMap(doc.data() as Map<String, dynamic>);
      })
          .toList();

      print('emptyLegRequests docs in querySnapshot: ${querySnapshot.docs.length}');
      print('Requests List: $requestsList');

      return requestsList;
    } catch (e) {
      print('Error fetching empty leg requests: $e');
      return [];
    }
  }

  // Method to fetch brokers by brokerIDs using the BrokerProfileData model
  Future<List<BrokerProfileData>> getBrokersByBrokerID(List<String> brokerIDs) async {
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
          return BrokerProfileData.fromMap(doc.id, doc.data() as Map<String, dynamic>);
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
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }


  // Method to fetch emptyLegRequests and associated brokers
  Future<List<Map<String, dynamic>>> getEmptyLegRequestsWithBrokers() async {
    try {

      // Get all the empty leg requests
      List<EmptyLegRequest> requests = await getEmptyLegRequests();

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
          orElse: () => BrokerProfileData(
            brokerID: 'Not found',
            name: 'Unknown',
            contact: 'N/A',
            rating: 0,
            website: 'N/A',
            company: 'N/A',
            country:  'N/A',
            license: [],
            email:  'N/A',
            paymentTerms:  'N/A',
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
  // Method to get emptyLegRequest data from Firestore based on nodeID
  Future<EmptyLegRequest> getEmptyLegRequest(String nodeID) async {
    try {
      // Reference to the emptyLegRequests collection and specific document
      DocumentReference docRef = _firestore.collection('emptyLegRequests').doc(nodeID);

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
      DocumentReference docRef = _firestore.collection('emptyLegRequests').doc(nodeID);
      // Update the 'status' field
      await docRef.update({
        'status': status,  // Field name 'status' and its new value
      });
      print('Status updated successfully');
    } catch (e) {
      print('Error updating status: $e');
      throw Exception('Error updating status: $e');  // Throwing an exception if error occurs
    }
  }
  Future<void> createNotification({
    required String brokerID,
    required String courierID,
    required String emptyLegRequestID,
    required String sentBy,
    required String message,
  }) async {
    try {
      // Reference to the notification collection
      CollectionReference notifications = _firestore.collection('notification');

      // Generate a new nodeID using Firestore's auto-ID generator
      String nodeID = notifications.doc().id;

      // Prepare the data to be saved
      Map<String, dynamic> notificationData = {
        'notificationID': nodeID,
        'emptyLegRequestID': emptyLegRequestID,
        'brokerID': brokerID,
        'courierID': courierID,
        'sentBy': sentBy,
        'message': message,
        'currentDateTime': DateTime.now().toUtc().toIso8601String(), // UTC format
      };

      // Save the data under the generated nodeID
      await notifications.doc(nodeID).set(notificationData);

      print('Notification saved successfully with nodeID: $nodeID');
    } catch (e) {
      print('Error saving notification: $e');
    }
  }
  Future<List<Map<String, dynamic>>> readNotifications() async {
    try {
      // Reference to the notification collection
      CollectionReference notifications = _firestore.collection('notification');

      // Fetch all documents in the collection
      QuerySnapshot querySnapshot = await notifications.get();

      // Convert documents to a list of maps
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
      await _firestore.collection('broker').doc(brokerID).get(const GetOptions(source: Source.server));

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
      await _firestore.collection('courier').doc(brokerID).get(const GetOptions(source: Source.server));

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

}