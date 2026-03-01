import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AiPredictionsPage extends StatelessWidget {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Predictions"), backgroundColor: Colors.yellow[700]),
      body: StreamBuilder(
        stream: _db.child('ai_results').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data is! DatabaseEvent) {
            return Center(child: CircularProgressIndicator());
          }

          final event = snapshot.data as DatabaseEvent;
          final data = event.snapshot.value as Map?;
          if (data == null) return Center(child: Text("No predictions yet"));

          final results = Map<String, dynamic>.from(data);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Issue Label: ${results['issueLabel']}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
