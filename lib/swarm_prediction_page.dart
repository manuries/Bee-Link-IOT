import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class SwarmPredictionPage extends StatelessWidget {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  double riskToValue(String risk) {
    switch (risk) {
      case "High": return 3.0;
      case "Medium": return 2.0;
      case "Low": return 1.0;
      default: return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Swarm Prediction"), backgroundColor: Colors.yellow[700]),
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
            final risk = v['swarmRisk'] ?? "Unknown";
            return riskToValue(risk);
          }).toList();

          return Column(
            children: [
              Text("Swarm Risk History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: entries.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [BarChartRodData(toY: entry.value, color: Colors.red)],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        axisNameWidget: Text("Time (entry order)"),
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Text("Risk (1=Low, 2=Medium, 3=High)"),
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
