import 'package:broker_flutter_pp/admin/UserProvider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserStatusChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final users = userProvider.activeUsers;
    final activeCount = users.where((u) => u.isActive).length;
    final inactiveCount = users.length - activeCount;

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: activeCount.toDouble(),
            title: 'Active\n$activeCount',
            color: Colors.green,
            radius: 60,
            titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: inactiveCount.toDouble(),
            title: 'Inactive\n$inactiveCount',
            color: Colors.red,
            radius: 60,
            titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
        sectionsSpace: 4,
        centerSpaceRadius: 30,
      ),
    );
  }
}
