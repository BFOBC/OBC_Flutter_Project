import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class NotificationHelper {
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY'; // 🔐 Replace with your actual FCM key

  static Future<void> saveTokenToFirestore(String collectionName,String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection(collectionName).doc(userId).set({
        'fcm_token': token,
      }, SetOptions(merge: true));
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance.collection(collectionName).doc(userId).update({
        'fcm_token': newToken,
      });
    });
  }

  static Future<void> sendNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$_serverKey',
    };

    final message = {
      'to': targetToken,
      'notification': {
        'title': title,
        'body': body,
      },
      'priority': 'high',
    };

    final response = await http.post(url, headers: headers, body: jsonEncode(message));
    print("Notification response: ${response.statusCode} - ${response.body}");
  }
}
