
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart'; // Import your ChatDetailScreen
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


class ChatListScreen extends StatefulWidget {
  final String userId;

  ChatListScreen({required this.userId});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    print('userId in initState: ${widget.userId}');

    // Example: Snackbar dikhana jab screen open ho
/*    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Your chats will be deleted in 3 days."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    });*/
  }

  Future<Map<String, String>> _getUserDetails(
      String userId, BuildContext context) async {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    print("_getUserDetailsChatList → userId=$userId role=${roleProvider.role}");

    try {
      if (roleProvider.role == UserRole.broker) {
        print("🔍 Broker login → courier details fetch kar rahe hain...");
        if (userId.isEmpty) return _unknownUser("Empty userId for courier");

        var courierRef =
        FirebaseFirestore.instance.collection('courier').doc(userId);

        print("📌 CourierRef path: ${courierRef.path}");

        var courierDoc = await courierRef.get();
        print("CourierDoc exists=${courierDoc.exists}, data=${courierDoc.data()}");

        if (courierDoc.exists && courierDoc.data() != null) {
          final data = courierDoc.data()!;
          return {
            'uid': courierDoc.id,
            'name': (data['name'] ?? '').toString().trim().isNotEmpty
                ? data['name']
                : 'Unknown Courier',
            'phoneNumber': data['phoneNumber'] ?? '',
            'profilePictureUrl': data['profilePictureUrl'] ?? '',
            'countryCode': data['countryCode'] ?? ''
          };
        } else {
          return _unknownUser("Courier record not found ya null hai");
        }
      } else if (roleProvider.role == UserRole.courier) {
        print("🔍 Courier login → broker details fetch kar rahe hain...");
        if (userId.isEmpty) return _unknownUser("Empty userId for broker");

        var brokerRef =
        FirebaseFirestore.instance.collection('broker').doc(userId);

        print("📌 BrokerRef path: ${brokerRef.path}");

        var brokerDoc = await brokerRef.get();
        print("BrokerDoc exists=${brokerDoc.exists}, data=${brokerDoc.data()}");

        if (brokerDoc.exists && brokerDoc.data() != null) {
          final data = brokerDoc.data()!;
          return {
            'uid': brokerDoc.id,
            'name': (data['name'] ?? '').toString().trim().isNotEmpty
                ? data['name']
                : 'Unknown Broker',
            'phoneNumber': data['phoneNumber'] ?? '',
            'countryCode': data['countryCode'] ?? '',
            'profilePictureUrl': data['profilePictureUrl'] ?? ''
          };
        } else {
          return _unknownUser("Broker record not found ya null hai");
        }
      } else {
        return _unknownUser("Role unknown hai: ${roleProvider.role}");
      }
    } catch (e) {
      return _unknownUser("❌ Exception aayi: $e");
    }
  }

  /// Helper → Unknown user map
  Map<String, String> _unknownUser(String reason) {
    print("🔄 Returning UnknownUser because: $reason");
    return {
      'uid': 'Unknown',
      'name': 'Unknown User',
      'phoneNumber': '',
      'countryCode': '',
      'profilePictureUrl': ''
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🔹 removes back button
        title: Text(
          'Chats',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Palette.googleBackground,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: widget.userId)
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
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  '⚠️ Your chats will be deleted in 3 days.',
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
                    Timestamp timestamp =
                        chat['lastMessageTimestamp'] ?? Timestamp.now();
                    DateTime date = timestamp.toDate();
                    String formattedDate =
                    DateFormat('MMMM d, y \'at\' h:mm a').format(date);

                    List<String> users = List<String>.from(chat['users']);
                    users.remove(widget.userId);
                    String otherUserId =
                    users.isNotEmpty ? users.first : 'Unknown';

                    print("otherUserId $otherUserId");

                    return FutureBuilder<Map<String, String>>(
                      future: _getUserDetails(otherUserId, context),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingTile();
                        }

                        if (userSnapshot.hasError || !userSnapshot.hasData) {
                          return _buildErrorTile();
                        }

                        String otherUserName =
                            userSnapshot.data!['name'] ?? 'Unknown';
                        String otherUserUid = userSnapshot.data!['uid'] ?? '';
                        String? countryCode = userSnapshot.data!['countryCode'];
                        String? phoneNumber = userSnapshot.data!['phoneNumber'];
                        String? completePhoneNumber = '$countryCode$phoneNumber';
                        String? profilePictureUrl =
                        userSnapshot.data!['profilePictureUrl'];
                        String displayLetter =
                        (otherUserName.isNotEmpty) ? otherUserName[0].toUpperCase() : '?';
                        // Stateful widget ke andar declare karo
                        int _unreadCount = 0; // local state for badge


                        print('userId: $widget.userId');

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chatId)
                              .collection('messages')
                              .where('isRead', isEqualTo: false)
                              .where('senderId', isNotEqualTo: widget.userId)
                              .snapshots(),
                          builder: (context, unreadSnapshot) {
                            if (unreadSnapshot.hasData) {
                              _unreadCount = unreadSnapshot.data!.docs.length;
                              print('chatId: $chatId, unreadCount: $_unreadCount');
                            }

                            return Column(
                              children: [
                                Stack(
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.only(right: 90, left: 16),
                                      leading: GestureDetector(
                                        onTap: () {
                                          if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                contentPadding: EdgeInsets.zero,
                                                backgroundColor: Colors.transparent,
                                                content: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    profilePictureUrl!,
                                                    width: 200,
                                                    height: 200,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: CircleAvatar(
                                          backgroundColor: Colors.blue[200],
                                          backgroundImage: (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
                                              ? NetworkImage(profilePictureUrl)
                                              : null,
                                          child: (profilePictureUrl == null || profilePictureUrl.isEmpty)
                                              ? Text(
                                            displayLetter,
                                            style: TextStyle(color: Colors.white),
                                          )
                                              : null,
                                        ),
                                      ),
                                      title: Text(otherUserName),
                                      subtitle: Text(lastMessage),
                                      onTap: () {
                                        // Navigate to detail
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatDetailScreen(userID: otherUserUid),
                                          ),
                                        );
                                      },
                                      onLongPress: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20)),
                                              child: Padding(
                                                padding: const EdgeInsets.all(20.0),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.warning_amber_rounded,
                                                        size: 50, color: Colors.redAccent),
                                                    const SizedBox(height: 15),
                                                    Text("Delete Chat",
                                                        style: TextStyle(
                                                            fontSize: 16, fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                        "Are you sure you want to delete this chat?",
                                                        textAlign: TextAlign.center),
                                                    const SizedBox(height: 20),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      children: [
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.green),
                                                          onPressed: () => Navigator.of(context).pop(),
                                                          child: Text("Cancel"),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.redAccent),
                                                          onPressed: () async {
                                                            Navigator.of(context).pop();
                                                            await _deleteChatFromFirebase(chatId);
                                                            Fluttertoast.showToast(
                                                                msg: "✅Chat deleted successfully!");
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
                                      },
                                    ),

                                    // 📅 Date
                                    Positioned(
                                      bottom: 1,
                                      right: 16,
                                      child: Text(
                                        formattedDate,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ),

                                    // 📞 Call Buttons
/*                                    if (completePhoneNumber != null && completePhoneNumber.isNotEmpty)
                                      Positioned(
                                        top: 10,
                                        right: 16,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.phone, color: Colors.green, size: 20),
                                              onPressed: () async {
                                                final Uri uri = Uri(
                                                    scheme: 'tel', path: completePhoneNumber);
                                                try {
                                                  bool launched = await launchUrl(
                                                      uri, mode: LaunchMode.externalApplication);
                                                  if (!launched)
                                                    Fluttertoast.showToast(msg: "Could not launch dialer");
                                                } catch (e) {
                                                  Fluttertoast.showToast(msg: "Error: $e");
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.add, color: Colors.teal, size: 20),
                                              onPressed: () async {
                                                String completePhoneNumber =
                                                '${countryCode ?? ''}${phoneNumber ?? ''}'
                                                    .replaceAll('+', '')
                                                    .replaceAll(' ', '')
                                                    .trim();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),*/

                                    // 🔴 Unread Badge
                                    if (/*_unreadCount > 0*/false )
                                      Positioned(
                                        right: 16,
                                        top: 12,
                                        child: Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            _unreadCount.toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
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
              ),
            ],
          );
        },
      ),
    );
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
