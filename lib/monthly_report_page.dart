import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MonthlyReportPage extends StatelessWidget {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  double trendToValue(String trend) {
    switch (trend) {
      case "Improving": return 3.0;
      case "Stable": return 2.0;
      case "Declining": return 1.0;
      default: return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hive Trend"), backgroundColor: Colors.yellow[700]),
      body: StreamBuilder(
        stream: _db.child('ai_history').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data is! DatabaseEvent) {
            return Center(child: CircularProgressIndicator());
          }

          final event = snapshot.data as DatabaseEvent;
          final data = event.snapshot.value as Map?;
          if (data == null) return Center(child: Text("No history yet"));

          final entries = data.entries.map((e) {
            final v = Map<String, dynamic>.from(e.value as Map);
            final ts = DateTime.tryParse(v['timestamp'] ?? '') ?? DateTime.now();
            final trendVal = trendToValue(v['trend'] ?? "Unknown");
            return FlSpot(ts.millisecondsSinceEpoch.toDouble(), trendVal);
          }).toList();

          entries.sort((a, b) => a.x.compareTo(b.x));

          return Column(
            children: [
              Text("Trend History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(spots: entries, isCurved: true, color: Colors.blue, barWidth: 3),
                    ],
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),   // remove top labels
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // remove right labels
                      bottomTitles: AxisTitles(
                        axisNameWidget: Text("Time"),
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                            return Text(DateFormat('HH:mm').format(date), style: TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Text("Trend (1=Declining, 2=Stable, 3=Improving)"),
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
