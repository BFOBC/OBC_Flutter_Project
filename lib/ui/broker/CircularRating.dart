import 'package:flutter/cupertino.dart';
import 'package:pie_chart/pie_chart.dart';

class CircularRating extends StatelessWidget {
  final Map<String, double> dataMap;
  final List<Color> colorList;

  const CircularRating({super.key, required this.dataMap, required this.colorList});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      dataMap: dataMap,
      animationDuration: const Duration(milliseconds: 800),
      chartRadius: MediaQuery.of(context).size.width / 4.0, // Adjusted for a slightly smaller size
      colorList: colorList,
      initialAngleInDegree: 0,
      chartType: ChartType.ring,
      ringStrokeWidth: 10, // Reduced thickness for a thinner chart
      centerText: "",
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
        showChartValueBackground: false,
        showChartValues: true,
        showChartValuesInPercentage: false,
        showChartValuesOutside: false,
        decimalPlaces: 0,
      ),
    );
  }
}
