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
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class AttachmentButton extends StatelessWidget {
  final String chatId;

  const AttachmentButton({Key? key, required this.chatId}) : super(key: key);

  void _showAttachmentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Pick Image'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFileToServer(context, pickerType: FileType.image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Pick PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFileToServer(
                    context,
                    pickerType: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Capture Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFileToServer(context, isCapture: true);
                },
              ),
/*              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Capture Video'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFileToServer(context, isCapture: true, isVideoCapture: true);
                },
              ),*/

            ],
          ),
        );
      },
    );
  }
  bool isFileSizeValid(File file, {int maxSizeInMB = 5}) {
    final bytes = file.lengthSync();
    final sizeInMB = bytes / (1024 * 1024);
    return sizeInMB <= maxSizeInMB;
  }



  Future<void> _uploadFileToServer(
      BuildContext context, {
        FileType? pickerType,
        List<String>? allowedExtensions,
        bool isCapture = false,
        bool isVideoCapture = false,
      }) async {
    File? file;

    if (isCapture) {
      final picker = ImagePicker();
      final media = isVideoCapture
          ? await picker.pickVideo(source: ImageSource.camera)
          : await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 1280,
      );
      if (media != null) {
        file = File(media.path);
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: pickerType ?? FileType.any,
        allowedExtensions: allowedExtensions,
      );
      if (result?.files.single.path != null) {
        file = File(result!.files.single.path!);
      }
    }

    if (file == null) return;

    // ===== File size check (limit: 5MB) =====
    final int maxSizeInBytes = 5 * 1024 * 1024; // 5 MB
    final int fileSize = await file.length();
    if (fileSize > maxSizeInBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File size exceeds 5MB. Please choose a smaller file.')),
      );
      return;
    }
    // ========================================

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    final uri = Uri.parse('https://mopogotechnologies.com/api/upload_chat_file.php');
    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = userId
      ..fields['chat_id'] = chatId
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final streamResp = await request.send();
      final response = await http.Response.fromStream(streamResp);
      Navigator.pop(context);

      final json = jsonDecode(response.body);
      if (json['status'] == 'success') {
        final url = json['url'];

        // Determine file type
        final fileExtension = file.path.split('.').last.toLowerCase();
        String fileType = 'unknown';
        if (['mp3', 'm4a', 'aac', 'wav', 'ogg'].contains(fileExtension)) {
          fileType = 'audio';
        } else if (['mp4', 'mov', 'avi', 'mkv'].contains(fileExtension)) {
          fileType = 'video';
        } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileExtension)) {
          fileType = 'image';
        }

        // ✅ Save file in local cache directory
        final dir = await getApplicationDocumentsDirectory();
        final fileName = file.path.split('/').last;
        final localFilePath = '${dir.path}/$fileName';
        final localFile = await file.copy(localFilePath);

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
          'isDownloaded': false,
          'fileType': fileType,
          'localFilePathSender': localFile.path, // 👈 added local path
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed, please try again later.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please check your connection.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: () => _showAttachmentBottomSheet(context),
    );
  }
}
