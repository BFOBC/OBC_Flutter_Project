import 'package:flutter/cupertino.dart';
import 'package:pie_chart/pie_chart.dart';

class CircularRating extends StatelessWidget {
  final Map<String, double> dataMap;
  final List<Color> colorList;
  final bool showLegendAtBottom; // 👈 New flag

  const CircularRating({
    super.key,
    required this.dataMap,
    required this.colorList,
    this.showLegendAtBottom = false, // 👈 Default false for other usages
  });

  @override
  Widget build(BuildContext context) {
    if (showLegendAtBottom) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PieChart(
            dataMap: dataMap,
            animationDuration: const Duration(milliseconds: 800),
            chartRadius: MediaQuery.of(context).size.width / 2.0,
            colorList: colorList,
            initialAngleInDegree: 0,
            chartType: ChartType.disc,
            ringStrokeWidth: 10,
            centerText: "",
            legendOptions: const LegendOptions(
              showLegendsInRow: false,
              legendPosition: LegendPosition.bottom, // 👈 Show legends at bottom
              showLegends: true,
              legendShape: BoxShape.circle,
              legendTextStyle: TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
            chartValuesOptions: const ChartValuesOptions(
              showChartValueBackground: false,
              showChartValues: true,
              showChartValuesInPercentage: false,
              showChartValuesOutside: false,
              decimalPlaces: 1,
            ),
          ),
        ],
      );
    } else {
      return PieChart(
        dataMap: dataMap,
        animationDuration: const Duration(milliseconds: 800),
        chartRadius: MediaQuery.of(context).size.width / 4.0, // slightly smaller
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.disc,
        ringStrokeWidth: 10,
        centerText: "",
        legendOptions: const LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.left, // 👈 Default
          showLegends: true,
          legendShape: BoxShape.circle,
          legendTextStyle: TextStyle(
            fontWeight: FontWeight.normal,
          ),
        ),
        chartValuesOptions: const ChartValuesOptions(
          showChartValueBackground: false,
          showChartValues: true,
          showChartValuesInPercentage: false,
          showChartValuesOutside: false,
          decimalPlaces: 1,
        ),
      );
    }
  }
}


