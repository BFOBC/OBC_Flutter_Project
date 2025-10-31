import 'dart:io';

import 'package:broker_flutter_pp/ui/chat/VideoPlayerWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final bool isSender;
  final String text;
  final String? fileUrl;
  final String? messageId;
  final String? chatId;
  final String? senderId;
  final Timestamp timestamp;
  final bool showTimestamp;

  ChatBubble({
    Key? key,
    required this.senderId,
    required this.chatId,
    required this.messageId,
    required this.isSender,
    required this.text,
    this.fileUrl,
    required this.timestamp,
    required this.showTimestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = isSender ? Colors.blue[100] : Colors.grey[300];
    final align = isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final alignment = isSender ? Alignment.centerRight : Alignment.centerLeft;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final margin = isSender
        ? const EdgeInsets.only(left: 50, right: 8, top: 4, bottom: 4)
        : const EdgeInsets.only(right: 50, left: 8, top: 4, bottom: 4);

    return Dismissible(
      key: Key(messageId!),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (senderId != currentUserId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You can only delete your own messages."),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.redAccent,
            ),
          );
          return false; // Cancel the dismiss
        }        return await showDeleteConfirmationDialog(context);

      },
      onDismissed: (direction) {
        deleteMessage(chatId!, messageId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted')),
        );
      },
      child: Column(
        crossAxisAlignment: align,
        children: [
          Align(
            alignment: alignment,
            child: Container(
              margin: margin,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fileUrl != null && fileUrl!.isNotEmpty)
                    _buildFilePreviewWithLoader(context, fileUrl!),
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ),
          ),
          if (showTimestamp)
            Padding(
              padding: isSender
                  ? const EdgeInsets.only(right: 12.0)
                  : const EdgeInsets.only(left: 12.0),
              child: Align(
                alignment: alignment,
                child: Text(
                  _formatTimestamp(timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Future<bool?> showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Disable dismiss on outside tap
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Delete Message"),
          ],
        ),
        content: const Text(
          "Are you sure you want to permanently delete this message? This action cannot be undone.",
          style: TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.cancel, color: Colors.grey),
            label: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_forever),
            label: const Text("Delete"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🟡 FILE SHIMMER HANDLER
  Widget _buildFilePreviewWithLoader(BuildContext context, String url) {
    final fileName = url.split('/').last;

    return FutureBuilder<String?>(
      future: _getLocalFilePathIfExists(fileName),
      builder: (context, snapshot) {
        final localPath = snapshot.data;
        final isPDF = url.toLowerCase().endsWith('.pdf');
        final isVideo = url.toLowerCase().endsWith('.mp4') ||
            url.toLowerCase().endsWith('.mov') ||
            url.toLowerCase().endsWith('.webm');
        final isAudio = url.toLowerCase().endsWith('.mp3') ||
            url.toLowerCase().endsWith('.wav') ||
            url.toLowerCase().endsWith('.m4a') ||
            url.toLowerCase().endsWith('.aac');

        if (localPath != null) {
          final file = File(localPath);

          if (isPDF) {
            return InkWell(
              onTap: () => OpenFile.open(file.path),
              child: Row(
                children: const [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 8),
                  Text('View PDF'),
                ],
              ),
            );
          } else if (isVideo) {
            return _buildVideoPlayer(file.path, isLocal: true);
          }else {
            return InkWell(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(child: Image.file(file)),
              ),
              child: Image.file(
                file,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            );
          }
        }

        // 🔁 If file not available locally
        if (isPDF) {
          return InkWell(
            onTap: () => launchUrl(Uri.parse(url)),
            child: Row(
              children: const [
                Icon(Icons.picture_as_pdf, color: Colors.red),
                SizedBox(width: 8),
                Text('View PDF'),
              ],
            ),
          );
        } else if (isVideo) {
          return _buildVideoPlayer(url, isLocal: false);
        } else {
          return FutureBuilder(
            future: precacheImage(NetworkImage(url), context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(child: Image.network(url)),
                  ),
                  child: Image.network(
                    url,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                return const SizedBox(
                  height: 150,
                  width: 150,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.grey),
                  ),
                );
              }
            },
          );
        }
      },
    );
  }

  Widget _buildVideoPlayer(String path, {required bool isLocal}) {
    return SizedBox(
      height: 200,
      width: 200,
      child: VideoPlayerWidget(
        videoUrl: path,
        isLocal: isLocal,
      ),
    );
  }

  Future<String?> _getLocalFilePathIfExists(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
    } catch (_) {}
    return null;
  }
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats') // replace with your collection
          .doc(chatId)
          .collection('messages') // replace if different
          .doc(messageId)
          .delete();
      print("Message $messageId deleted successfully");
    } catch (e) {
      print("Error deleting message: $e");
    }
  }


  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final formattedDate = DateFormat('MMMM d, y \'at\' h:mm a').format(dateTime);
    return formattedDate;
  }

}



