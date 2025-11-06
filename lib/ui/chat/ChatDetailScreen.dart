
import 'dart:io';
import 'package:broker_flutter_pp/data/notification/NotificationService.dart';
import 'package:broker_flutter_pp/ui/broker/SearchCourier.dart';
import 'package:broker_flutter_pp/ui/chat/AttachmentButton.dart';
import 'package:broker_flutter_pp/ui/chat/ChatBubble.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ChatDetailScreen extends StatefulWidget {
  final String userID;

  ChatDetailScreen({required this.userID});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String chatId = ''; // Variable to store chatId

  DateTime? lastShownTime;

  @override
  void initState() {
    super.initState();
    print("ChatDetailScreen:initState");
    print(widget.userID);
    _getChatId();
    markMessagesAsReadWithoutIndex();
  }
  Future<void> markMessagesAsReadWithoutIndex() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false) // sirf unread messages
          .get();

      // Filter locally for messages sent by other user
      final otherUserMessages = snapshot.docs.where(
            (doc) => doc['senderId'] != widget.userID,
      );

      for (var doc in otherUserMessages) {
        await doc.reference.update({'isRead': true});
      }

      print("✅ All unread messages marked as read (without index) for chatId: $chatId");
    } catch (e) {
      print("❌ Error marking messages as read: $e");
    }
  }

// Function to get chatId based on userIDs
  Future<void> _getChatId() async {
    String currentUserID = FirebaseAuth.instance.currentUser?.uid ?? '';
    String otherUserID = widget.userID;

    if (currentUserID.isNotEmpty && otherUserID.isNotEmpty) {
      String id1 = currentUserID.compareTo(otherUserID) < 0
          ? currentUserID
          : otherUserID;
      String id2 = currentUserID.compareTo(otherUserID) < 0
          ? otherUserID
          : currentUserID;
      String generatedChatId = '$id1-$id2';

      // ✅ Just assign the chatId, do not create the document yet
      setState(() {
        chatId = generatedChatId;
      });
    }
  }

  Future<Map<String, String>> _getUserDetails(String userId,
      BuildContext context) async {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    print("_getUserDetails $userId");

    try {
      if (roleProvider.role == UserRole.broker) {
        var courierDoc = await FirebaseFirestore.instance
            .collection('courier')
            .doc(userId)
            .get();
        if (courierDoc.exists && courierDoc.data() != null) {
          return {
            'uid': courierDoc.id,
            'name': courierDoc['name'] ?? 'Unknown Courier'
          };
        }
      } else if (roleProvider.role == UserRole.courier) {
        var brokerDoc = await FirebaseFirestore.instance
            .collection('broker')
            .doc(userId)
            .get();
        if (brokerDoc.exists && brokerDoc.data() != null) {
          return {
            'uid': brokerDoc.id,
            'name': brokerDoc['name'] ?? 'Unknown Broker'
          };
        }
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
    return {'uid': 'Unknown', 'name': 'Unknown User'};
  }

  void _sendMessage() async {
    String messageText = _textController.text.trim();
    print("DEBUG: Message Text: '$messageText'");
    print("DEBUG: Chat ID: '$chatId'");

    if (messageText.isNotEmpty && chatId.isNotEmpty) {
      _textController.clear();

      try {
        String currentUserID =
            FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
        print("DEBUG: Current User ID: $currentUserID");

        Timestamp timestamp = Timestamp.now();

        DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

        // ✅ Check if chat doc exists
        var chatDoc = await chatRef.get();
        print("DEBUG: Chat doc exists? ${chatDoc.exists}");
        if (!chatDoc.exists) {
          await chatRef.set({
            'users': [currentUserID, widget.userID],
          });
          print("DEBUG: Created new chat document");
        }

        await chatRef.collection('messages').add({
          'senderId': currentUserID,
          'messageText': messageText,
          'timestamp': timestamp,
          'fileUrl': null,
          'isRead': false,
          'isDownloaded': false
        });
        print("DEBUG: Message saved to Firestore");

        // ✅ Update chat metadata
        await chatRef.set({
          'lastMessage': messageText,
          'lastMessageTimestamp': timestamp,
        }, SetOptions(merge: true));
        print("DEBUG: Chat metadata updated");

        final userInfo = await NotificationService.getUserFcmInfo(context);
        final token = await NotificationService.getUserFcmTokenById(widget.userID);
        print("Opposite role FCM Token: $token");
        print("FCM Token: $token");
        print("DEBUG: User FCM Info: $userInfo");



        if (userInfo != null) {
          final params = {
            "title": "New Message",
            "token": token,
            "type": "new_msg",
            "screen": "ChatDetailScreen",
            "data": {
              "senderName": userInfo['name'],
              "userID": currentUserID,
              "chatId": chatId,
            }
          };

          print("=====================================");
          print("📩 Notification Params:");
          params.forEach((key, value) {
            if (value is Map) {
              print("➡️ $key : {");
              value.forEach((k, v) => print("     $k : $v"));
              print("}");
            } else {
              print("➡️ $key : $value");
            }
          });
          print("=====================================");

          await NotificationService.sendNotification(
            title: params["title"] as String,
            toToken: params["token"] as String,
            type: params["type"] as String,
            screen: params["screen"] as String,
            extraData: params["data"] as Map<String, dynamic>,
          );

          print("✅ ChatNotification sent!");
        }

      } catch (error) {
        print('ERROR sending message: $error');

/*        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send message: $error"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );*/
      }
    } else {
      print("DEBUG: Either message is empty or chatId is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Message cannot be empty"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Palette.googleBackground,
        iconTheme: const IconThemeData(
          color: Colors.white, // Back button white
        ),
        title: FutureBuilder<Map<String, String>>(
          future: _getUserDetails(widget.userID, context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'Loading...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Text(
                'Unknown User',
                style: TextStyle(color: Colors.white, fontSize: 14),
              );
            }

            String userName = snapshot.data!['name'] ?? 'Unknown User';

            // 🔹 Get current user role
            final roleProvider = Provider.of<RoleProvider>(context, listen: false);
            final isBroker = roleProvider.role == UserRole.broker;

            // 🔹 Clickable only if broker is logged in
            return GestureDetector(
              onTap: isBroker
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SearchCourier(courierKey: widget.userID),
                  ),
                );
              }
                  : null, // 🚫 No redirection if courier logged in
              child: Text(
                userName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
      body: chatId
          .isEmpty // Add check to show loading state until chatId is available
          ? const Center(
          child: CircularProgressIndicator()) // Show a loading spinner
          : Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // 🧱 Always work with Map safely
                    final messageDoc = messages[index];
                    final data = (messageDoc.data() ?? {}) as Map<String, dynamic>;
                    final messageId = messageDoc.id;

                    // 🧩 Safely extract values with fallback
                    final text = data['messageText']?.toString() ?? '';
                    final senderId = data['senderId']?.toString() ?? '';
                    final isSender = senderId == (FirebaseAuth.instance.currentUser?.uid ?? '');
                    final isDownloaded = data['isDownloaded'] is bool ? data['isDownloaded'] : false;

                    final timestamp = (data['timestamp'] is Timestamp)
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    // 🕒 Compare minute-level timestamps
                    bool showTime = true;
                    if (lastShownTime != null) {
                      final diff = lastShownTime!.difference(timestamp).abs();
                      if (diff.inMinutes < 1) showTime = false;
                    }
                    lastShownTime = timestamp;

                    // 📁 Safe file path check
                    String fileUrl = '';
                    if (isSender) {
                      fileUrl = data['localFilePathSender']?.toString() ?? '';
                    } else {
                      fileUrl = data['fileUrl']?.toString() ?? '';
                    }

                    // fallback agar dono empty hon
                    if (fileUrl.isEmpty) {
                      fileUrl = data['fileUrl']?.toString() ?? '';
                    }

                    print('fileUrl: $fileUrl');
                    print('isSender: $isSender');
                    print('isDownloaded: $isDownloaded');

                    // 🧠 Auto-download safely (avoid crash)
                    if (!isSender && !isDownloaded && (data['fileUrl']?.toString().isNotEmpty ?? false)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _downloadFileAndUpdate(messageDoc, context);
                      });
                    }

                    // 💬 Safe ChatBubble creation
                    return ChatBubble(
                      senderId: senderId,
                      chatId: chatId,
                      messageId: messageId,
                      isSender: isSender,
                      text: text,
                      fileUrl: fileUrl,
                      timestamp: data['timestamp'] ?? Timestamp.now(),
                      showTimestamp: showTime,
                    );
                  },
                );


              },
            ),
          ),
          SafeArea(
            bottom: true,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Enter message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        prefixIcon: AttachmentButton(
                            chatId: chatId), // 👈 inside input
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: Palette.primaryColor,
                    mini: true,
                    child: const Icon(
                      Icons.send,
                      color: Colors.white, // 👈 white color set
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _downloadFileAndUpdate(QueryDocumentSnapshot message, BuildContext context) async {
    try {
      final ctx = context;
      final fileUrl = message['fileUrl'];
      final fileName = fileUrl
          .split('/')
          .last;

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';

      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // 🔁 Update Firestore to prevent re-download
        await message.reference.update({
          'isDownloaded': true,
          'localPath': filePath, // 👈 add this
        });
        print("deleteFileFromServer going to call $fileUrl");

        deleteFileFromServer(ctx, fileUrl);
        // ✅ Show success snackbar
/*        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ File downloaded: $fileName'),
            backgroundColor: Colors.green,
          ),
        );*/
      } else {
        // ❌ Show error snackbar
/*        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ Failed to download file (Status: ${response.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );*/
      }
    } catch (e) {
      // ❌ Show error snackbar
/*      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Download error: $e'),
          backgroundColor: Colors.red,
        ),
      );*/
    }
  }

  Future<void> deleteFileFromServer(BuildContext context, String fileUrl) async {
    if (fileUrl.isEmpty) {
      print("🚨 fileUrl is empty");
      return;
    }

    final cleanPath = Uri.parse(fileUrl).path; // /uploads/abc.jpg

    final uri = Uri.parse('https://mopogotechnologies.com/api/delete_file_by_url.php');

    try {
      var request = http.MultipartRequest('POST', uri);
      request.fields['fileUrl'] = cleanPath;

      print('📤 Sending multipart payload: fileUrl = $cleanPath');

      var response = await request.send();

      final respStr = await response.stream.bytesToString();
      print('📥 Status: ${response.statusCode}');
      print('📥 Body: $respStr');

/*      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Deleted: ${respStr}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed: ${response.statusCode}')),
        );
      }*/
    } catch (e) {
      print('🚨 Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚨 Error: $e')),
      );
    }
  }
  @override
  void dispose() {
    print("ChatDetailScreen:dispose");
    print(widget.userID);
    NotificationService.currentRoute = null;
    super.dispose();
  }

}
