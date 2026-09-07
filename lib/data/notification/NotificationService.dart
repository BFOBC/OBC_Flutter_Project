import 'dart:convert';
import 'package:broker_flutter_pp/ui/broker/mission/BrokerMissions.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart';
import 'package:broker_flutter_pp/ui/chat/ChatListScreen.dart';
import 'package:broker_flutter_pp/ui/common/screens/DrawerScreen.dart';
import 'package:broker_flutter_pp/ui/courier/missions/CompleteMilestone.dart';
import 'package:broker_flutter_pp/ui/courier/missions/CourierMissions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../ui/common/utils/RoleProvider.dart';

// Aur main.dart ka import karo
import 'package:broker_flutter_pp/main.dart';

class NotificationService {
  static const String _serverUrl =
      "https://mercivatrust.org/fcm-server/send_notification.php";
  static String? currentRoute;

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static Map<String, dynamic>? _pendingPayload;
  static bool _isHandlingClick = false;

  // add these private fields near top of the class
  static DateTime? _lastNavTime;
  static const int _navDebounceMs = 2500; // ignore nav attempts within 2.5s
  /// Init service
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    // Initialize local notifications first (register tap callback)
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && details.payload!.isNotEmpty) {
          final data = _normalizePayload(details.payload!);
          print("📦 Local notif tapped: $data");

          // ✅ Sirf foreground ke liye navigate
          if (navigatorKeyMain.currentState != null) {
            _handleNotificationClick(data);
          } else {
            _pendingPayload = data;
          }
        }
      },
    );

    // After initialize, check if app was launched by tapping a local notification
    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        (launchDetails?.notificationResponse?.payload?.isNotEmpty ?? false)) {
      final payloadStr = launchDetails!.notificationResponse!.payload!;
      final data = _normalizePayload(payloadStr);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKeyMain.currentState == null) {
          _pendingPayload = data;
        } else {
          _handleNotificationClick(data);
        }
      });
    }

    // 🔔 Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("📩 Foreground message: ${message.data}");

      final title = message.notification?.title ?? message.data['title'] ?? '';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      // Save raw message.data as payload (stringified)
      await _showLocalNotification(
        title: title,
        body: body,
        payload: jsonEncode(message.data),
      );
    });

    // Terminated → cold start
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print("📩 Opened from terminated: ${initialMessage.data}");
      final data = _normalizePayload(initialMessage.data);
      if (navigatorKeyMain.currentState == null) {
        _pendingPayload = data;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationClick(data);
        });
      }
    }

    // Background → user taps FCM notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📩 Opened from background: ${message.data}");
      final data = _normalizePayload(message.data);
      if (navigatorKeyMain.currentState == null) {
        _pendingPayload = data;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationClick(data);
        });
      }
    });
  }

  static Map<String, dynamic> _normalizePayload(dynamic payload) {
    // payload might be a stringified JSON or a Map (Map<dynamic,dynamic>)
    if (payload is String) {
      try {
        payload = jsonDecode(payload);
      } catch (_) {}
    }

    if (payload is Map) {
      // convert dynamic map -> Map<String, dynamic>
      final map = Map<String, dynamic>.from(payload);
      // If message has nested 'data' object (common when sending { data: {...} })
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data']);
      }
      return map;
    }

    return <String, dynamic>{};
  }

  static void handlePendingPayload() {
    if (_pendingPayload != null) {
      final nav = navigatorKeyMain.currentState;
      if (nav != null) {
        nav.push(
          MaterialPageRoute(
              builder: (_) =>
                  screenRoutes[_pendingPayload!['screen']]!(_pendingPayload!)),
        );
        _pendingPayload = null;
      }
    }
  }

  /// Handle navigation dynamically
  static final Map<String, Widget Function(Map<String, dynamic> data)>
      screenRoutes = {
    "DrawerScreen": (data) => DrawerScreen(),
    "CourierMissions": (data) => CourierMissions(),
    "BrokerMissionScreen": (data) => BrokerMissions(),
    "ChatDetailScreen": (data) => ChatDetailScreen(
          userID: data['userID'] ?? 'defaultUser',
        ),
    // Add more screens here
  };

  static void _handleNotificationClick(Map<String, dynamic> data) {
    final screen = data['screen'];
    print("🔀 Navigate to: $screen with payload: $data");

    if (screen != null && screenRoutes.containsKey(screen)) {
      final nav = navigatorKeyMain.currentState;
      if (nav == null) {
        print("⚠️ Navigator not ready, skipping");
        return;
      }

      final idPart = (data['chatId'] ?? data['userID'] ?? '').toString();
      final screenKey = "$screen::$idPart";

      if (currentRoute == screenKey) {
        print("⚠️ Already on $screenKey, no navigation");
        return;
      }

      // ✅ Lock karo until dispose
      currentRoute = screenKey;

      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => screenRoutes[screen]!(data),
        ),
        (Route<dynamic> route) => route.isFirst, // ✅ sirf root bacha rahega
      );
    } else {
      print("⚠️ No matching screen found for: $screen");
    }
  }

  /// Get logged-in user's FCM token & name
  static Future<Map<String, String?>?> getUserFcmInfo(context) async {
    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      String collectionName =
          roleProvider.role == UserRole.broker ? 'broker' : 'courier';

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "token": data['fcm_token'] as String?,
          "name": data['name'] as String?,
        };
      }
      return null;
    } catch (e) {
      print("❌ Error fetching FCM info: $e");
      return null;
    }
  }

  /// Get Courier Name & FCM Token
  static Future<Map<String, String?>?> getCourierNameAndTokenById(
      String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courier')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "name": data['name'] as String?,
          "token": data['fcm_token'] as String?,
        };
      }
      return null;
    } catch (e) {
      print("❌ Error fetching Courier Name & Token for userID $userId: $e");
      return null;
    }
  }

  static Future<Map<String, String?>?> getBrokerNameAndTokenById(
      String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('broker')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "name": data['name'] as String?,
          "token": data['fcm_token'] as String?,
        };
      }
      return null;
    } catch (e) {
      print("❌ Error fetching Courier Name & Token for userID $userId: $e");
      return null;
    }
  }

  /// Get opposite role user's FCM token
  static Future<String?> getUserFcmTokenById(String userId) async {
    try {
      // Check in broker collection
      var doc = await FirebaseFirestore.instance
          .collection('broker')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fcm_token'] as String?;
      }

      // Check in courier collection
      doc = await FirebaseFirestore.instance
          .collection('courier')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fcm_token'] as String?;
      }

      return null; // userID kisi bhi collection me nahi mila
    } catch (e) {
      print("❌ Error fetching FCM token for userID $userId: $e");
      return null;
    }
  }

  /// Send notification with dynamic screen
/*
  static Future<bool> sendNotification({
    required String title,
    required String toToken,
    required String type,
    required String screen,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final Map<String, String> templates = {
        "broker_request": "{name} has sent you a job request.",
        "courier_accept": "{name} has accepted your request.",
        "courier_reject": "{name} has rejected your request.",
        "job_completed": "{name} has marked the job as completed.",
        "decline_job": "{name} has decline your Job",
        "accepted_job": "{name} has accepted your Job",
        "job_started": "{name} has started the Job",
        "mile_stone_completed": "{name} has completed a milestone.",
        "new_msg": "{name} has sent you a message",
      };

      if (!templates.containsKey(type)) {
        throw Exception("Invalid notification type: $type");
      }

      final senderName = extraData?["senderName"] ?? "Someone";
      final body = templates[type]!.replaceAll("{name}", senderName);

      final mergedData = {
        "screen": screen, // screen comes from caller
        ...?extraData,
      };

      final response = await http.post(
        Uri.parse(_serverUrl),
        body: {
          "token": toToken,
          "title": title,
          "body": body,
          "data": jsonEncode(mergedData),
        },
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent: $type → $screen");
        return true;
      } else {
        print("❌ Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error sending notification: $e");
      return false;
    }
  }
*/

  /// Send notification in a universal way
  static Future<bool> sendNotification({
    required String title,
    required String toToken, // existing parameter name, no change needed
    required String type,
    required String screen,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      const Map<String, String> templates = {
        "broker_request": "{name} has sent you a job request.",
        "courier_accept": "{name} has accepted your request.",
        "courier_reject": "{name} has rejected your request.",
        "job_completed": "{name} has marked the job as completed.",
        "decline_job": "{name} has declined your Job.",
        "accepted_job": "{name} has accepted your Job.",
        "job_started": "{name} has started the Job.",
        "mile_stone_completed": "{name} has completed a milestone.",
        "new_msg": "{name} has sent you a message.",
      };

      if (!templates.containsKey(type)) {
        throw Exception("Invalid notification type: $type");
      }

      final senderName = (extraData?["senderName"] ?? "Someone").toString();
      final body = templates[type]!.replaceAll("{name}", senderName);

      // ✅ Universal payload matching PHP backend
      final requestBody = {
        "token": toToken,
        "title": title,
        "body": body,
        "data": {
          "screen": screen,
          "senderName": senderName,
          "userID": extraData?["userID"] ?? "",
          "chatId": extraData?["chatId"] ?? "",
          "testParam": "testing",
        },
        "priority": "high"
      };

      // 🔹 Send POST request
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent: type=$type, screen=$screen");
        print("📦 Request Body: $requestBody");
        print("Response: ${response.body}");
        return true;
      } else {
        print("❌ Failed to send notification. Code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e, stack) {
      print("⚠️ Error sending notification: $e");
      print(stack);
      return false;
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  //from background
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      "default_channel",
      "General Notifications",
      channelDescription: "App notifications",
      importance: Importance.high,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: payload, // 👈 yeh JSON string store ho rahi hai
    );
  }
}
