import 'package:broker_flutter_pp/ui/chat/profileScreen.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import '../common/charts/CircularChartScreen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../broker/PlaceNewJob.dart';

class MainScreen extends StatefulWidget {
  final String userName;
  final double rating;
  final String userImage;

  const MainScreen({
    Key? key,
    required this.userName,
    required this.rating,
    required this.userImage,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showPieChart = true;
  bool _showProfile = false;

  // Sample data for the pie chart
  final Map<String, double> dataMap = {
    "Red": 40,
    "Green": 30,
    "Blue": 30,
  };

  final List<Color> colorList = [
    Colors.red,
    Colors.green,
    Colors.blue,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile and Rating'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Image
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(widget.userImage),
            ),
            const SizedBox(height: 10),

            // Centered Text for Name
            Center(
              child: Text(
                'Name: ${widget.userName}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Display the Rating with Non-Interactive Stars
            RatingBarIndicator(
              rating: widget.rating,
              itemBuilder: (context, index) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              itemCount: 5,
              itemSize: 30.0,
              direction: Axis.horizontal,
            ),
            const SizedBox(height: 10),

            // Buttons for Show Rating and Show Profile
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showPieChart = true;
                      _showProfile = false;
                    });
                  },
                  child: const Text('Show Rating'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showProfile = true;
                      _showPieChart = false;
                    });
                  },
                  child: const Text('Show Profile'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Conditionally show Profile or Pie Chart
            if (_showProfile)
              ProfileScreen(name: widget.userName),
            if (_showPieChart)
              CircularChart(
                dataMap: dataMap,
                colorList: colorList,
              ),
          ],
        ),
      ),
    );
  }
}

class CircularChart extends StatelessWidget {
  final Map<String, double> dataMap;
  final List<Color> colorList;

  CircularChart({required this.dataMap, required this.colorList});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      dataMap: dataMap,
      animationDuration: const Duration(milliseconds: 800),
      chartRadius: MediaQuery.of(context).size.width / 2.2,
      colorList: colorList,
      initialAngleInDegree: 0,
      chartType: ChartType.ring,
      ringStrokeWidth: 32,
      centerText: "Distribution",
      legendOptions: const LegendOptions(
        showLegendsInRow: false,
        legendPosition: LegendPosition.right,
        showLegends: true,
        legendShape: BoxShape.circle,
        legendTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      chartValuesOptions: const ChartValuesOptions(
        showChartValueBackground: true,
        showChartValues: true,
        showChartValuesInPercentage: true,
        showChartValuesOutside: false,
        decimalPlaces: 1,
      ),
    );
  }
}
