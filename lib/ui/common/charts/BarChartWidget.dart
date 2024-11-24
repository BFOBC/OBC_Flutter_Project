
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BarChartWidget extends StatelessWidget {
  const BarChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Define the number of bars you want to display
    const numberOfBars = 12;

    // Calculate the dynamic bar width with spacing
    final barWidth = (screenWidth - 64 - (numberOfBars - 1) * 8) / numberOfBars; // 8 pixels space between bars

    return BarChart(
      BarChartData(
        barGroups: [
          for (int i = 1; i <= numberOfBars; i++) // Generate bars dynamically
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: (i * 2 + 10).toDouble(), // Example data
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.blue], // Gradient colors
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: barWidth,
                borderRadius: BorderRadius.zero,
              ),
            ]),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40, // Space for the left titles
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(color: Colors.black));
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide bottom titles
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide right titles
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
      ),
    );
  }
}