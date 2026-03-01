import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HiveHealthPage extends StatelessWidget {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hive Health"), backgroundColor: Colors.yellow[700]),
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
            final score = (v['healthScore'] ?? 0).toDouble();
            return FlSpot(ts.millisecondsSinceEpoch.toDouble(), score);
          }).toList();

          entries.sort((a, b) => a.x.compareTo(b.x));

          return Column(
            children: [
              Text("Health Score History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,   // ✅ force Y-axis to start at 0
                    maxY: 100, // ✅ force Y-axis to end at 100 (health score range)
                    lineBarsData: [
                      LineChartBarData(spots: entries, isCurved: true, color: Colors.green, barWidth: 3),
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
                        axisNameWidget: Text("Health Score"),
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(value.toInt().toString()); // ✅ show actual integer values
                          },
                        ),
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
