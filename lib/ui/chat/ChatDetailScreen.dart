import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  ChatDetailScreen({required this.chatId});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to send a message
  void _sendMessage() async {
    if (_textController.text.isNotEmpty) {
      try {
        String currentUserID=getCurrentUserId();
        await _firestore.collection('chats').add({
          'message': _textController.text,
          'senderId': currentUserID,
          'receiverId': widget.chatId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _textController.clear();
      } catch (error, stackTrace) {
        print('Exception: $error');
        print('StackTrace: $stackTrace');
      }
    }
  }
  String getCurrentUserId() {
    // Replace this with your actual logic to retrieve the user ID
    return FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Palette.secondaryColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bilawal',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            Image.asset(
              'assets/avatar.png',
              width: 40,
              height: 40,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
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
                    final text = message['message'] ?? '';
                    final isSender = message['senderId'] == getCurrentUserId; // Replace with dynamic check
                    return ChatBubble(
                      isSender: isSender,
                      text: text,
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

  const ChatBubble({
    super.key,
    required this.isSender,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
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
    );
  }
}
