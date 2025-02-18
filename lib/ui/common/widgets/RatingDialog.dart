import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:broker_flutter_pp/ui/common/models/Rating.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
    return WillPopScope( // Prevents closing with back button
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.profilePicture),
                  backgroundColor: Colors.grey[300],
                ),
                SizedBox(height: 16),
                Text(
                  widget.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                RatingBar.builder(
                  initialRating: 0,
                  minRating: 1,
                  itemSize: 30,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemBuilder: (context, _) =>
                      Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: "Leave a comment...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Allows only letters and spaces
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          print("Rating: $_rating, Comment: ${_commentController
                              .text}");
                          giveRating();
                          //Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Submit", style: TextStyle(color: Colors
                            .white)),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                         // giveRating();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Later", style: TextStyle(color: Colors
                            .white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      // Show error if rating is not given
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please provide a rating before submitting.")),
      );
      return;
    }

    if (_commentController.text
        .trim()
        .isEmpty) {
      // Show error if comment is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a comment before submitting.")),
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


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rating submitted successfully!")),
      );

      Navigator.of(context).pop(); // Close dialog after success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit rating: $e")),
      );
    }
  }
}
