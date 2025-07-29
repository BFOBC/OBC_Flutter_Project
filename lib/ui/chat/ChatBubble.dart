import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final bool isSender;
  final String text;
  final String? fileUrl;
  final Timestamp timestamp;
  final bool showTimestamp;

  const ChatBubble({
    Key? key,
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

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: align,
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
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Text(
              _formatTimestamp(timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  /// 🟡 FILE SHIMMER HANDLER
  Widget _buildFilePreviewWithLoader(BuildContext context, String url) {
    final fileName = url.split('/').last;

    return FutureBuilder<String?>(
      future: _getLocalFilePathIfExists(fileName),
      builder: (context, snapshot) {
        final localPath = snapshot.data;

        if (localPath != null) {
          final file = File(localPath);

          if (url.endsWith('.pdf')) {
            return InkWell(
              onTap: () => OpenFile.open(file.path),
              child: Row(
                children: const [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 8),
                  Text('View PDF (Local)'),
                ],
              ),
            );
          } else {
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

        // 🔁 If not downloaded yet, fallback to online preview
        if (url.endsWith('.pdf')) {
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
            },
          );
        }
      },
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


  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final formattedDate = DateFormat('MMMM d, y \'at\' h:mm a').format(dateTime);
    return formattedDate;
  }

}



