
import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/widgets/ProfileAvatar.dart';
import 'package:broker_flutter_pp/ui/common/models/Rating.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class RatingDialog extends StatefulWidget {
  final String profilePicture = "https://via.placeholder.com/150";
  final String name = "Broker";
  final Task task;

  // Constructor to accept selectedTab and task
  RatingDialog({Key? key, required this.task}) : super(key: key);

  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 0;
  TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: FutureBuilder<String?>(
          future: _getProfileImageUrl(context), // 👈 async method niche likhi hui hai
          builder: (context, snapshot) {
            String? imageUrl = snapshot.data;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileAvatar(
                      url: imageUrl,
                      radius: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    RatingBar.builder(
                      initialRating: 0,
                      minRating: 1,
                      itemSize: 30,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Leave a comment...",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              print("Rating: $_rating, Comment: ${_commentController.text}");
                              giveRating();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Submit",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Later",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  void giveRating() async {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    String role = roleProvider.role == UserRole.broker
        ? 'broker'
        : 'courier';
    final FirestoreService service = FirestoreService(context);

    if (_rating == 0) {
      Fluttertoast.showToast(
        msg: "Please provide a rating",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );

      return;
    }

    if (_commentController.text
        .trim()
        .isEmpty) {
      // Show error if comment is empty
      Fluttertoast.showToast(
        msg: "Please enter a comment",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
      return;
    }

    try {
      final String ratingID = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();

      Rating rating = Rating(
        ratingID: ratingID,
        courierID: "",
        // Replace with actual ID
        brokerID: widget.task.brokerId.toString(),
        // Replace with actual ID
        jobID: widget.task.emptyLegRequestID.toString(),
        // Replace with actual Job ID
        jobType: "delivery",
        // Replace with actual Job Type
        rating: _rating.toDouble(),
        dateTime: DateTime.now().toIso8601String(),
        comment:_commentController.text.trim(),
        from:role,
      );

      await service.addRating(rating); // Save to Firestore

      // If broker is logged in, they rate a courier (assign courierID)
      if (roleProvider.role == UserRole.broker) {
        service.updateRatingFlag(widget.task.emptyLegRequestID.toString(),"isBrokerRated","true"); // Save to Firestore
      }else{
        service.updateRatingFlag(widget.task.emptyLegRequestID.toString(),"isCourierRated","true"); // Save to Firestore

      }

      Fluttertoast.showToast(
        msg: "Rating submitted successfully!",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );


      Navigator.of(context).pop(); // Close dialog after success
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to submit rating: $e",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );

    }
  }

  Future<String?> _getProfileImageUrl(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('⚠️ No logged-in user found.');
      return null;
    }

    // 🔹 Get role from provider
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    String role = roleProvider.role == UserRole.broker ? 'broker' : 'courier';
    final FirestoreService service = FirestoreService(context);

    print('👤 Logged-in Role: $role');
    print('👤 Current User ID: ${currentUser.uid}');
    try {
      String? imageUrl;

      if (role == 'courier') {
        // ✅ Courier logged in → show Broker profile
        imageUrl = await service.getBrokerProfilePicture(widget.task.brokerId.toString());
        print('🟢 Broker profile image URL: $imageUrl');
      } else {
        // ✅ Broker logged in → show Courier profile
        imageUrl = await service.getCourierProfilePicture(currentUser.uid);
        print('🟢 Courier profile image URL: $imageUrl');
      }

      if (imageUrl == null || imageUrl.isEmpty) {
        print('⚠️ No profile image found.');
      }

      return imageUrl;
    } catch (e) {
      print('❌ Error determining profile image: $e');
      return null;
    }
  }


}
