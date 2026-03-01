import 'package:firebase_database/firebase_database.dart';

class HiveLogicService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> updateSensorData(String sensor, dynamic value) async {
    await _db.child('sensors/$sensor').set({
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
    //  No need to call fetchAiPredictions — backend listener handles it
  }
}
