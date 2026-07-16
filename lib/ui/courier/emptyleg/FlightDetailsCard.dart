import 'package:flutter/material.dart';

class FlightDetailsCard extends StatelessWidget {
  final String brokerName;
  final String brokerProfileUrl;
  final double brokerRating;
  final VoidCallback onTap;

  FlightDetailsCard({
    required this.brokerName,
    required this.brokerProfileUrl,
    required this.brokerRating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.all(10),
        child: Container(
          width: 250,
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              SizedBox(height: 10),
              Text(
                brokerName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < brokerRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
