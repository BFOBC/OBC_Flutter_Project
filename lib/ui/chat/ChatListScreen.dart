import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

import '../common/utils/RoleProvider.dart';
import 'ChatDetailScreen.dart';

class ChatListScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>().role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('chats').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chats available.'));
          }

          final chatDocs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chat = chatDocs[index];

              return FutureBuilder<Map<String, dynamic>?>(
                future: fetchProfile(chat['receiverId'], role), // Fetch user profile
                builder: (context, profileSnapshot) {
                  if (!profileSnapshot.hasData) {
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: const Text('Loading...'),
                      subtitle: Text(chat['message']),
                    );
                  }

                  final profileData = profileSnapshot.data!;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(profileData['profilePicture'] ?? ''), // Profile picture
                      child: profileData['profilePicture'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(profileData['name'] ?? 'Unknown User'), // Name
                    subtitle: Text(chat['message']),
                    trailing: Text(
                      (chat['timestamp'] as Timestamp).toDate().toLocal().toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      // Navigate to the chat detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(chatId: chat.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
  Future<Map<String, dynamic>?> fetchProfile(String receiverId, UserRole role) async {
    try {
      // Determine the collection to query based on the role
      final collection = role == UserRole.broker ? 'courier' : 'broker';

      // Fetch the user document from the appropriate collection
      DocumentSnapshot userDoc = await _firestore.collection(collection).doc(receiverId).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        print('User not found for ID: $receiverId');
        return null;
      }
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }
}
