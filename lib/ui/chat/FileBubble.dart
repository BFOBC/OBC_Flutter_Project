import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class FileBubble extends StatelessWidget {
  final bool isSender;
  final String url;
  final DateTime timestamp;
  final bool showTimestamp;

  const FileBubble({
    super.key,
    required this.isSender,
    required this.url,
    required this.timestamp,
    required this.showTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = url.endsWith('.png') || url.endsWith('.jpg') || url.endsWith('.jpeg');

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSender ? Palette.primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: isImage
                ? Image.network(url, width: 200, fit: BoxFit.cover)
                : GestureDetector(
              onTap: () async {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Open File',
                    style: TextStyle(color: isSender ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),
          ),
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
              child: Text(
                DateFormat('MMMM d, y \'at\' h:mm a').format(timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}
