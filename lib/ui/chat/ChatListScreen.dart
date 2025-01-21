import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart'; // Import your ChatDetailScreen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart';
import 'package:provider/provider.dart';

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
            'name': courierDoc['name'] ?? 'Unknown Courier'
          };
        }
      } else if (roleProvider.role == UserRole.courier) {
        var brokerDoc = await FirebaseFirestore.instance.collection('broker').doc(userId).get();
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text(
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
            return Center(child: Text('No chats yet'));
          }

          var chatDocs = snapshot.data!.docs;

          return ListView.builder(
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

                  if (userSnapshot.hasError || !userSnapshot.hasData) {
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

                  String otherUserName = userSnapshot.data!['name']!;
                  String otherUserUid = userSnapshot.data!['uid']!;

                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(child: Text(otherUserName[0].toUpperCase())),
                        title: Text(otherUserName),
                        subtitle: Text(lastMessage),
                        trailing: Text('${date.hour}:${date.minute}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(userID: otherUserUid),
                            ),
                          );
                        },
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
          );

        },
      ),
    );
  }
}

