import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart'; // Import your ChatDetailScreen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart'; // Import your ChatDetailScreen
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatListScreen extends StatelessWidget {
  final String userId; // Current user's ID

  ChatListScreen({required this.userId});

  Future<Map<String, String>> _getUserDetails(String userId, BuildContext context) async {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    try {
      if (roleProvider.role == UserRole.broker) {
        var courierDoc = await FirebaseFirestore.instance.collection('courier').doc(userId).get();
        if (courierDoc.exists && courierDoc.data() != null) {
          return {
            'uid': courierDoc.id,
            'name': courierDoc['name'] ?? 'Unknown Courier',
            'phoneNumber': courierDoc['phoneNumber'] ?? ''
          };
        }
      } else if (roleProvider.role == UserRole.courier) {
        var brokerDoc = await FirebaseFirestore.instance.collection('broker').doc(userId).get();
        if (brokerDoc.exists && brokerDoc.data() != null) {
          return {
            'uid': brokerDoc.id,
            'name': brokerDoc['name'] ?? 'Unknown Broker',
            'phoneNumber': brokerDoc['phoneNumber'] ?? ''
          };
        }
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
    return {'uid': 'Unknown', 'name': 'Unknown User', 'phoneNumber': ''};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Palette.googleBackground,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation to see it here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );

          }

          var chatDocs = snapshot.data!.docs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: Colors.yellow[100],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  '⚠️ Your chats will be deleted in 15 days.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    var chat = chatDocs[index];
                    String chatId = chat.id;
                    String lastMessage = chat['lastMessage'] ?? 'No message';
                    Timestamp timestamp = chat['lastMessageTimestamp'] ?? Timestamp.now();
                    DateTime date = timestamp.toDate();

                    List<String> users = List<String>.from(chat['users']);
                    users.remove(userId);
                    String otherUserId = users.isNotEmpty ? users.first : 'Unknown';

                    return FutureBuilder<Map<String, String>>(
                      future: _getUserDetails(otherUserId, context),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return _buildLoadingTile();
                        }

                        if (userSnapshot.hasError || !userSnapshot.hasData) {
                          return _buildErrorTile();
                        }

                        String otherUserName = userSnapshot.data!['name'] ?? 'Unknown';
                        String otherUserUid = userSnapshot.data!['uid'] ?? '';
                        String? phoneNumber = userSnapshot.data!['phoneNumber'];

                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(child: Text(otherUserName[0].toUpperCase())),
                              title: Text(otherUserName),
                              subtitle: Text(lastMessage),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                                  if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: Icon(Icons.phone, color: Colors.green),
                                      onPressed: () async {
                                        final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
                                        try {
                                          bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          if (!launched) {
                                            Fluttertoast.showToast(msg: "Could not launch dialer");
                                          }
                                        } catch (e) {
                                          Fluttertoast.showToast(msg: "Error: $e");
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add, color: Colors.teal),
                                      onPressed: () async {
                                        final Uri waUri = Uri.parse("https://wa.me/$phoneNumber");
                                        if (await canLaunchUrl(waUri)) {
                                          await launchUrl(waUri, mode: LaunchMode.externalApplication);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Could not launch WhatsApp')),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                if (otherUserUid.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailScreen(userID: otherUserUid),
                                    ),
                                  );
                                }
                              },
                                onLongPress: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.warning_amber_rounded, size: 50, color: Colors.redAccent),
                                              const SizedBox(height: 15),
                                              Text(
                                                "Delete Chat",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                "Are you sure you want to delete this chat?",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 14, color: Colors.black54),
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  // Cancel Button
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: Text("Cancel"),
                                                  ),

                                                  // Delete Button
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.redAccent,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      Navigator.of(context).pop(); // Close dialog first
                                                      await _deleteChatFromFirebase(chatId);

                                                      Fluttertoast.showToast(
                                                        msg: "✅Chat deleted successfully!",
                                                        toastLength: Toast.LENGTH_SHORT,
                                                        gravity: ToastGravity.BOTTOM,
                                                        backgroundColor: Colors.green,
                                                        textColor: Colors.white,
                                                        fontSize: 16.0,
                                                      );

                                                    },
                                                    child: Text("Delete"),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30.0),
                              child: Divider(color: Palette.firebaseGrey),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

            ],
          );
        },
      ),
    );
  }
  Future<void> _deleteChatFromLocalDb(String chatId) async {
    // Yahan apni local DB logic lagayein
    // Example: await LocalDatabase.instance.deleteChat(chatId);
    print("Deleted from local DB: $chatId");
  }
  Widget _buildLoadingTile() {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text('Loading...'),
          subtitle: Text('Fetching user info...'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildErrorTile() {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(child: Icon(Icons.error)),
          title: Text('Error loading user'),
          subtitle: Text('Could not retrieve user details'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _deleteChatFromFirebase(String chatId) async {
    try {
      final messagesRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages');

      // 🔁 Get all messages
      final messagesSnapshot = await messagesRef.get();

      // 🔄 Delete each message
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // ❌ Delete the chat document after messages are deleted
      await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();

      Fluttertoast.showToast(
        msg: "✅ Chat and messages deleted!",
        backgroundColor: Colors.green.shade700,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: '❌ Delete failed: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }


}


