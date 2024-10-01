import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../common/charts/BarChartWidget.dart';
import 'CardStackWidget.dart';

class EmptyLegMainScreen extends StatelessWidget {
  const EmptyLegMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Action to add a new Empty Leg
                // Navigate to the Add Empty Leg screen or show a dialog
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue, // Bubble background color
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.add, color: Colors.white), // Plus icon
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: BarChartWidget(), // Use the BarChartWidget here
            ),
            SizedBox(height: 16), // Spacing between the chart and card stack
            CardStackWidget(), // Add the card stack widget below the chart
          ],
        ),
      ),
    );
  }
}
