import 'dart:convert';
import 'package:http/http.dart' as http;

class SensorData {
  final String timestamp;
  final String deviceId;
  final int gasLevel;
  final int fireLevel;
  final bool gasDetected;
  final bool fireDetected;
  final bool sprinklerOn;
  final bool ledOff;

  SensorData({
    required this.timestamp,
    required this.deviceId,
    required this.gasLevel,
    required this.fireLevel,
    required this.gasDetected,
    required this.fireDetected,
    required this.sprinklerOn,
    required this.ledOff,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: json['timestamp'] ?? '',
      deviceId: json['device_id'] ?? 'Unknown',
      gasLevel: json['gas_level'] ?? 0,
      fireLevel: json['fire_level'] ?? 0,
      gasDetected: json['gas_detected'] ?? false,
      fireDetected: json['fire_detected'] ?? false,
      sprinklerOn: json['sprinkler_on'] ?? false,
      ledOff: json['led_off'] ?? false,
    );
  }
}

class ApiService {
  // REPLACE WITH YOUR PC's IP ADDRESS
  // If using Android Emulator, use '10.0.2.2' instead of localhost
  static const String duplicate_url = "http://192.168.1.10:5000/api/latest"; 
  static const String baseUrl = "http://192.168.1.10:5000/api/latest"; // Matches ESP32 code IP

  static Future<SensorData?> fetchLatestData() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'no_data') {
          return null;
        }
        return SensorData.fromJson(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
      return null;
    }
  }
}
