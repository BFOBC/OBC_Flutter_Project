import 'package:broker_flutter_pp/ui/broker/model/BrokerProfileData.dart';
import 'package:broker_flutter_pp/ui/common/models/EmptyLegRequest.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final BuildContext context;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService(this.context);

  Future<void> saveEmptyLegRequest(EmptyLegRequest request) async {
    try {
      // Reference to the collection
      CollectionReference requests = _firestore.collection('emptyLegRequests');

      // Create a new document with an auto-generated ID
      DocumentReference docRef = requests.doc();

      // Update the nodeID dynamically
      request.nodeID = docRef.id;

      // Save the request with the updated nodeID
      await docRef.set(request.toJson());
      print('Request saved with nodeID: ${request.nodeID}');
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

      // Query brokers with the brokerID from the emptyLegRequests collection
      QuerySnapshot querySnapshot = await brokers
          .where(FieldPath.documentId, whereIn: brokerIDs)
          .get();


      print('brokers querySnapshot Data');
      print(querySnapshot.docs.length);
      // Convert the documents to a list of BrokerProfileData objects
      List<BrokerProfileData> brokersList = querySnapshot.docs
          .map((doc) => BrokerProfileData.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      print('brokersList Data');
      print(brokersList.length);
      return brokersList;
    } catch (e) {
      print('Error fetching brokers: $e');
      return [];
    }
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
}