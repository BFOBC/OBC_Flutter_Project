import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class CircularRating extends StatelessWidget {
  final Map<String, double> dataMap;
  final List<Color> colorList;

  const CircularRating({Key? key, required this.dataMap, required this.colorList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PieChart(
      dataMap: dataMap,
      animationDuration: const Duration(milliseconds: 800),
      chartRadius: MediaQuery.of(context).size.width / 4.5,
      colorList: colorList,
      initialAngleInDegree: 0,
      chartType: ChartType.ring,
      ringStrokeWidth: 28,
      centerText: "Jobs",
      legendOptions: const LegendOptions(
        showLegendsInRow: false,
        legendPosition: LegendPosition.right,
        showLegends: true,
        legendShape: BoxShape.circle,
        legendTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Palette.textPrimary,
        ),
      ),
      chartValuesOptions: const ChartValuesOptions(
        showChartValueBackground: false,
        showChartValues: true,
        showChartValuesInPercentage: true,
        showChartValuesOutside: true,
        decimalPlaces: 0,
        chartValueStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Palette.textPrimary,
        ),
      ),
    );
  }
}
