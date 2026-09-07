
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:broker_flutter_pp/ui/common/widgets/ProfileAvatar.dart';
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
      backgroundColor: Palette.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Palette.primaryColor,
        elevation: 0,
        title: const Text('Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Palette.primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Palette.primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 44, color: Palette.primaryColor),
                  ),
                  const SizedBox(height: 20),
                  const Text('No conversations yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Palette.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Start a conversation to see it here.', style: TextStyle(fontSize: 13, color: Palette.textSecondary)),
                ],
              ),
            );
          }

          var chatDocs = snapshot.data!.docs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning banner
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Palette.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Palette.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Palette.warning, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Chats are automatically deleted after 3 days.',
                        style: TextStyle(color: Palette.warning, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    var chat = chatDocs[index];
                    String chatId = chat.id;
                    String lastMessage = chat['lastMessage'] ?? 'No message';
                    Timestamp timestamp = chat['lastMessageTimestamp'] ?? Timestamp.now();
                    DateTime date = timestamp.toDate();
                    String formattedDate = _formatChatTime(date);

                    List<String> users = List<String>.from(chat['users']);
                    users.remove(widget.userId);
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
                        String? countryCode = userSnapshot.data!['countryCode'];
                        String? phoneNumber = userSnapshot.data!['phoneNumber'];
                        String? profilePictureUrl = userSnapshot.data!['profilePictureUrl'];
                        String displayLetter = otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?';
                        int _unreadCount = 0;

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
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Palette.surface,
                                borderRadius: BorderRadius.circular(14),
                                elevation: 1,
                                shadowColor: Palette.primaryColor.withOpacity(0.06),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatDetailScreen(userID: otherUserUid),
                                      ),
                                    );
                                  },
                                  onLongPress: () => _showDeleteDialog(context, chatId),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        GestureDetector(
                                          onTap: () {
                                            if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  contentPadding: EdgeInsets.zero,
                                                  backgroundColor: Colors.transparent,
                                                  content: ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.network(profilePictureUrl!, width: 200, height: 200, fit: BoxFit.cover),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Stack(
                                            children: [
                                              ProfileAvatar(
                                                url: profilePictureUrl,
                                                radius: 26,
                                                backgroundColor: Palette.primaryColor.withOpacity(0.15),
                                              ),
                                              if (_unreadCount > 0)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    width: 16,
                                                    height: 16,
                                                    decoration: const BoxDecoration(color: Palette.errorColor, shape: BoxShape.circle),
                                                    child: Center(
                                                      child: Text(_unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // Name + message
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      otherUserName,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: _unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                                                        color: Palette.textPrimary,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    formattedDate,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: _unreadCount > 0 ? Palette.primaryColor : Palette.textSecondary,
                                                      fontWeight: _unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                lastMessage,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: _unreadCount > 0 ? Palette.textPrimary : Palette.textSecondary,
                                                  fontWeight: _unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 8),
                                        const Icon(Icons.chevron_right_rounded, color: Palette.textDisabled, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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

  String _formatChatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return DateFormat('h:mm a').format(date);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(date);
    return DateFormat('MMM d').format(date);
  }

  void _showDeleteDialog(BuildContext context, String chatId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: Palette.errorColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline_rounded, color: Palette.errorColor, size: 28),
                ),
                const SizedBox(height: 16),
                const Text('Delete Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Palette.textPrimary)),
                const SizedBox(height: 8),
                const Text('Are you sure you want to delete this conversation?', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Palette.textSecondary)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.textSecondary,
                          side: const BorderSide(color: Palette.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _deleteChatFromFirebase(chatId);
                          Fluttertoast.showToast(msg: "Chat deleted successfully!");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Delete'),
                      ),
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

  Widget _buildLoadingTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Palette.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: Palette.border, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 120, decoration: BoxDecoration(color: Palette.border, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 180, decoration: BoxDecoration(color: Palette.surfaceVariant, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Palette.surface, borderRadius: BorderRadius.circular(14)),
        child: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Palette.errorColor, size: 20),
            SizedBox(width: 10),
            Text('Could not load conversation', style: TextStyle(color: Palette.textSecondary, fontSize: 13)),
          ],
        ),
      ),
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
