import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userID;
  ChatDetailScreen({required this.userID});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String chatId = '';  // Variable to store chatId

  DateTime? lastShownTime;
  @override
  void initState() {
    super.initState();
    _getChatId();
  }


// Function to get chatId based on userIDs
  Future<void> _getChatId() async {
    String currentUserID = FirebaseAuth.instance.currentUser?.uid ?? '';
    String otherUserID = widget.userID;

    if (currentUserID.isNotEmpty && otherUserID.isNotEmpty) {
      // Ensure that the chatId is unique and consistent by sorting the user IDs
      String id1 = currentUserID.compareTo(otherUserID) < 0 ? currentUserID : otherUserID;
      String id2 = currentUserID.compareTo(otherUserID) < 0 ? otherUserID : currentUserID;
      String generatedChatId = '$id1-$id2';

      // Check if chat already exists
      var chatDoc = await _firestore.collection('chats').doc(generatedChatId).get();

      if (!chatDoc.exists) {
        // Create a new chat document if it doesn't exist
        await _firestore.collection('chats').doc(generatedChatId).set({
          'users': [currentUserID, otherUserID],
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        chatId = generatedChatId; // Set the chatId to use in the message collection
      });
    }
  }
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
  void _sendMessage() async {
    if (_textController.text.isNotEmpty && chatId.isNotEmpty) {
      try {
        String currentUserID = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
        String messageText = _textController.text.trim();
        Timestamp timestamp = Timestamp.now();

        DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

        // Add new message to the messages subcollection within the chat
        await chatRef.collection('messages').add({
          'senderId': currentUserID,
          'messageText': messageText,
          'timestamp': timestamp,
          'isRead': false,
        });

        // Update chat metadata with last message details
        await chatRef.set({
          'users': FieldValue.arrayUnion([currentUserID]), // Ensure user ID is added to array
          'lastMessage': messageText,
          'lastMessageTimestamp': timestamp,
        }, SetOptions(merge: true)); // Merge to avoid overwriting existing data

        _textController.clear();
      } catch (error) {
        print('Error sending message: $error');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Palette.googleBackground,
        iconTheme: const IconThemeData(
          color: Colors.white, // Back button ka color white karne ke liye
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

            return Text(
              userName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            );
          },
        ),
      ),
      body: chatId.isEmpty // Add check to show loading state until chatId is available
          ? const Center(child: CircularProgressIndicator()) // Show a loading spinner
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
                    final message = messages[index];
                    final text = message['messageText'] ?? '';
                    final isSender = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                    final timestamp = (message['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                    // Compare minute-level timestamps to avoid repeating
                    bool showTime = true;
                    if (lastShownTime != null) {
                      Duration diff = lastShownTime!.difference(timestamp).abs();
                      if (diff.inMinutes < 1) {
                        showTime = false;
                      }
                    }

                    lastShownTime = timestamp;

                    return ChatBubble(
                      isSender: isSender,
                      text: text,
                      timestamp: timestamp,
                      showTimestamp: showTime,
                    );
                  },
                );

              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Palette.primaryColor,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isSender;
  final String text;
  final DateTime? timestamp; // now optional
  final bool showTimestamp;  // control visibility

  const ChatBubble({
    super.key,
    required this.isSender,
    required this.text,
    this.timestamp,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTimestamp = timestamp != null
        ? DateFormat('MMMM d, y \'at\' h:mm a').format(timestamp!)
        : '';

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
        isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isSender ? Palette.primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: isSender ? const Radius.circular(15) : Radius.zero,
                bottomRight: isSender ? Radius.zero : const Radius.circular(15),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isSender ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          if (showTimestamp && timestamp != null) // 👈 show only if required
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Text(
                formattedTimestamp,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


