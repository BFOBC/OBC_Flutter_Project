import 'package:broker_flutter_pp/ui/common/screens/DrawerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingDialog extends StatelessWidget {
  final String brokerName;
  final String brokerImage;

  RatingDialog({required this.brokerName, required this.brokerImage});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        height: 350, // Adjust height as needed
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Broker Image at the top
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(brokerImage), // Replace with real image
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(height: 16),
            // Broker Name
            Text(
              brokerName,
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
              itemBuilder: (context, index) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                // You can handle rating updates here
                print("Rating: $rating");
              },
            ),
            Spacer(),
            // 'Later' Button
            ElevatedButton(
              onPressed: () async {
                // Close the rating dialog first
                Navigator.of(context).pop();

                // Ensure navigation happens after pop completes
                Future.microtask(() {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => DrawerScreen()),
                        (route) => false, // Clear all previous screens
                  );
                });
              },


              child: Text("Later"),
            ),
          ],
        ),
      ),
    );
  }
}
