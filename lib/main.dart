import 'package:flutter/material.dart';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';
import 'hive_logic_service.dart';

import 'ai_predictions_page.dart';
import 'swarm_prediction_page.dart';
import 'monthly_report_page.dart';
import 'hive_health_page.dart';

// Entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(BLinkApp());
}

// Main App
class BLinkApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'B Link',
      theme: ThemeData(
        primaryColor: Colors.yellow[700],
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: DashboardPage(),
    );
  }
}

// Dashboard Page
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.yellow[700]!, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.bug_report, color: Colors.black, size: 26), // bee icon substitute
            SizedBox(width: 8),
            Text(
              'Bee Link',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            SizedBox(width: 8),
            BeeAnimation(size: 24),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Your Smart Hive Monitor',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,

              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              //  Sensor Info Boxes
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      liveInfoBox('air_quality', 'Air Quality', Colors.orange, '', Icons.cloud),
                      liveInfoBox('lid_status', 'Lid Status', Colors.green, '', Icons.lock_open),
                      liveInfoBox('weight', 'Weight', Colors.blue, 'g', Icons.scale),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      liveInfoBox('sound', 'Sound', Colors.purple, '', Icons.volume_up),
                      liveInfoBox('humidity', 'Humidity', Colors.teal, '%', Icons.water_drop),
                      liveInfoBox('temperature', 'Temperature', Colors.red, '°C', Icons.thermostat),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Live Alert Section
              StreamBuilder(
                stream: FirebaseDatabase.instance.ref('alerts').onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data is DatabaseEvent) {
                    final data = (snapshot.data! as DatabaseEvent).snapshot.value as Map?;
                    if (data == null) {
                      return SizedBox.shrink(); // No alerts → show nothing
                    }

                    final alerts = data.values.map((e) => e as Map).toList();

                    return Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.red, Colors.redAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 8, offset: Offset(2, 4))
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'ALERT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Column(
                          children: alerts.map((alert) {
                            final sensor = alert['sensor'] ?? 'Unknown';
                            final value = alert['value'] ?? '';
                            return Text(
                              '$sensor triggered ($value)',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }
                  return SizedBox.shrink(); // No data yet
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Info Box Widget
Widget infoBox(String title, String value, Color color, IconData icon) {
  return Container(
    width: 110,
    height: 90,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withOpacity(0.2), color.withOpacity(0.5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: Offset(2, 4))],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

// Live Info Box Widget (Firebase Stream)
Widget liveInfoBox(String sensorKey, String title, Color color, String unit, IconData icon) {
  return StreamBuilder(
    stream: FirebaseDatabase.instance.ref('sensors/$sensorKey').onValue,
    builder: (context, snapshot) {
      if (snapshot.hasData && snapshot.data is DatabaseEvent) {
        final data = (snapshot.data! as DatabaseEvent).snapshot.value as Map?;
        final value = data?['value'] ?? 'N/A';
        return infoBox(title, '$value $unit', color, icon);
      }
      return infoBox(title, 'Loading...', color, icon);
    },
  );
}
// Drawer Menu
class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.yellow[700],
        child: ListView(
          children: [
            DrawerHeader(
              child: Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.black),
              title: Text('AI Predictions', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AiPredictionsPage()));
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text('Swarm Prediction', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SwarmPredictionPage()));
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.show_chart, color: Colors.blue),
              title: Text('Monthly Report', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MonthlyReportPage()));
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.health_and_safety, color: Colors.green),
              title: Text('Hive Health', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HiveHealthPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Bee Animation Widget
class BeeAnimation extends StatefulWidget {
  final double size;
  BeeAnimation({this.size = 20});

  @override
  _BeeAnimationState createState() => _BeeAnimationState();
}

class _BeeAnimationState extends State<BeeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: Duration(seconds: 3))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 10).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(sin(_animation.value * pi) * 5, -_animation.value),
            child: Icon(Icons.bug_report, // bee icon substitute
                color: Colors.black, size: widget.size),
          );
        });
  }
}
