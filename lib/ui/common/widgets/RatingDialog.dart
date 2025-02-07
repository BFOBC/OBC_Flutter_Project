import 'package:broker_flutter_pp/ui/common/screens/DrawerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingDialog extends StatefulWidget {
  final String profilePicture="https://via.placeholder.com/150";
  final String name="Broker";
  RatingDialog();

  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 0;
  TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        height: 400, // Adjust height to accommodate comment section
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Broker Image at the top
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(widget.profilePicture),
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(height: 16),
            // Broker Name
            Text(
              widget.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            // Rating Stars
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              itemSize: 30,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            SizedBox(height: 16),
            // Comment TextField
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Leave a comment...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            Spacer(),
            // Submit and Later Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle submission logic (store rating and comment in Firestore)
                    print("Rating: $_rating, Comment: ${_commentController.text}");
                    Navigator.of(context).pop();
                  },
                  child: Text("Submit"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Later"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
