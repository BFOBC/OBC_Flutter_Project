// Required dependencies in pubspec.yaml:
//   file_picker: ^6.1.1
//   http: ^0.13.5
//   shimmer: ^3.0.0

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AttachmentButton extends StatelessWidget {
  final String chatId;

  const AttachmentButton({Key? key, required this.chatId}) : super(key: key);

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final uri = Uri.parse('https://mopogotechnologies.com/api/upload_chat_file.php');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['user_id'] = userId;
      request.fields['chat_id'] = chatId;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        Navigator.pop(context); // Close loader

        final json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          final url = json['url'];
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .add({
            'senderId': userId,
            'messageText': '',
            'fileUrl': url,
            'timestamp': Timestamp.now(),
            'isRead': false,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json['message'] ?? 'Upload failed')));
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: () => _pickAndUploadFile(context),
    );
  }
}
