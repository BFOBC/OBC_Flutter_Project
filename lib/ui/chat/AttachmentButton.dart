// Required dependencies in pubspec.yaml:
//   file_picker: ^6.1.1
//   http: ^0.13.5
//   shimmer: ^3.0.0

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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


/*
  Future<void> _uploadFileToServer(
      BuildContext context, {
        FileType? pickerType,
        List<String>? allowedExtensions,
        bool isCapture = false,
        bool isVideoCapture = false,
      }) async {
    File? file;

    // =================== PICK FILE ===================
    if (isCapture) {
      final picker = ImagePicker();
      final media = isVideoCapture
          ? await picker.pickVideo(source: ImageSource.camera)
          : await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 1280,
      );
      if (media != null) file = File(media.path);
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: pickerType ?? FileType.any,
        allowedExtensions: allowedExtensions,
      );
      if (result?.files.single.path != null) file = File(result!.files.single.path!);
    }

    if (file == null) return;

    // =================== FILE SIZE CHECK ===================
    final int maxSizeInBytes = 5 * 1024 * 1024; // 5 MB
    final int fileSize = await file.length();
    if (fileSize > maxSizeInBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File size exceeds 5MB. Please choose a smaller file.')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    // =================== SHOW LOADING ===================
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 180),
          receiveTimeout: const Duration(seconds: 180),
        ),
      );

// NEW SSL fix
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };

// SIRF EK rakho, dono nahi
      dio.interceptors.add(LogInterceptor(
        request: true,
        requestBody: true,
        requestHeader: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        logPrint: (obj) => print("💬 DIO LOG: $obj"),
      ));


      // =================== FORM DATA ===================
      final formData = FormData.fromMap({
        'user_id': userId,
        'chat_id': chatId,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last, // important
        ),
      });

      // =================== POST REQUEST ===================
      final response = await dio.post(
        'https://mopogotechnologies.com/api/upload_chat_file.php',
        data: formData,
          options: Options(headers: {'Accept': 'application/json'}),
        onSendProgress: (sent, total) {
          print('🔹 Upload progress: ${((sent / total) * 100).toStringAsFixed(0)}%');
        },
      );

      Navigator.pop(context); // hide loading

      print('✅ Server Response: ${response.data}');

      final jsonResp = response.data;
      if (jsonResp['status'] == 'success') {
        final url = jsonResp['url'];

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

        // Save locally
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
          'localFilePathSender': localFile.path,
        });

        print('💾 File saved locally at ${localFile.path}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed, please try again later.')),
        );
      }
    } on DioException catch (e) {
      Navigator.pop(context);
      print('❌ Dio Error Type: ${e.type}');
      print('❌ Dio Error Message: ${e.message}');
      print('❌ Dio Error Stack: ${e.stackTrace}');
      String message = 'Network error. Please check your connection.';
      if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timed out. Try again.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        message = 'Upload taking too long. Try again.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'Server not responding. Try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
      print('❌ Unexpected Error: $e');
    }
  }
*/

  Future<void> _uploadFileToServer(
      BuildContext context, {
        FileType? pickerType,
        List<String>? allowedExtensions,
        bool isCapture = false,
        bool isVideoCapture = false,
      }) async {
    File? file;

    // ── Pick file ──────────────────────────────────────────────
    if (isCapture) {
      final picker = ImagePicker();
      final media = isVideoCapture
          ? await picker.pickVideo(source: ImageSource.camera)
          : await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 1280,
      );
      if (media != null) file = File(media.path);
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

    // ── Size check (5 MB) ──────────────────────────────────────
    final int fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File size exceeds 5MB. Please choose a smaller file.')),
      );
      return;
    }

    // ── Auth check ─────────────────────────────────────────────
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    // ── Show loader ────────────────────────────────────────────
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ── Determine MIME type ───────────────────────────────────
      final ext = file.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(ext);

      // ── Build multipart request manually ─────────────────────
      final uri = Uri.parse('https://mopogotechnologies.com/api/upload_chat_file.php');

      final request = http.MultipartRequest('POST', uri)
        ..headers['User-Agent'] = 'PostmanRuntime/7.36.0'
        ..fields['chat_id'] = chatId
        ..fields['user_id'] = userId
        ..files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );

      final streamResp = await request.send();
      final response = await http.Response.fromStream(streamResp);

      // ── Close loader ──────────────────────────────────────────
      if (context.mounted) Navigator.pop(context);

      debugPrint('Upload status: ${response.statusCode}');
      debugPrint('Upload body: ${response.body}');

      // ── Handle non-JSON response (e.g. 406 HTML page) ─────────
      if (response.statusCode != 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${response.statusCode}. Contact support.')),
          );
        }
        return;
      }

      // ── Parse JSON ────────────────────────────────────────────
      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unexpected server response. Contact support.')),
          );
        }
        return;
      }

      if (json['status'] == 'success') {
        final url = json['url'];

        // ── File type label ───────────────────────────────────
        String fileType = 'unknown';
        if (['mp3', 'm4a', 'aac', 'wav', 'ogg'].contains(ext)) {
          fileType = 'audio';
        } else if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
          fileType = 'video';
        } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
          fileType = 'image';
        } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'].contains(ext)) {
          fileType = 'document';
        }

        // ── Cache file locally ────────────────────────────────
        final dir = await getApplicationDocumentsDirectory();
        final fileName = file.path.split('/').last;
        final localFile = await file.copy('${dir.path}/$fileName');

        // ── Save message to Firestore ─────────────────────────
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
          'localFilePathSender': localFile.path,
        });
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(json['message'] ?? 'Upload failed, please try again.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close loader if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

// ── Helper: MIME type from extension ─────────────────────────────
  String _getMimeType(String ext) {
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt': 'text/plain',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: () => _showAttachmentBottomSheet(context),
    );
  }
}
