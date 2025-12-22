import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dashboard_utils.dart';

class DashboardChart extends StatelessWidget {
  final List<Map<String, dynamic>> rapports;

  const DashboardChart({super.key, required this.rapports});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: rapports.asMap().entries.map((e) {
                final r = e.value;
                final ventes = totalFromMap(
                  calcVentes(
                    r["index_super"].cast<String, int>(),
                    r["index_super_n1"].cast<String, int>(),
                  ),
                );
                return FlSpot(e.key.toDouble(), ventes.toDouble());
              }).toList(),
            )
          ],
        ),

      ),
    );
  }
}
