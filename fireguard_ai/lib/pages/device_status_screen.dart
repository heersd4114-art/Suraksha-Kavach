import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceStatusScreen extends StatefulWidget {
  const DeviceStatusScreen({super.key});

  @override
  State<DeviceStatusScreen> createState() => _DeviceStatusScreenState();
}

class _DeviceStatusScreenState extends State<DeviceStatusScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Future<String?> _deviceFuture;

  @override
  void initState() {
    super.initState();
    _deviceFuture = _getDeviceId();
  }

  // Load deviceId
  Future<String?> _getDeviceId() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return null;

    try {
      final snapshot = await _firestore
          .collection('devices')
          .where('ownerUid', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      print("Error fetching device: $e");
    }

    return 'VAYUSHURAKSHA: #GD&L 1'; // Fallback
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background handled by Theme (Color(0xFFFAFAFA))
      appBar: AppBar(
        title: const Text("UNIT STATUS CHECK"),
        // Theme handles colors
        centerTitle: true,
      ),

      body: FutureBuilder<String?>(
        future: _deviceFuture,
        builder: (context, deviceSnap) {
          if (deviceSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!deviceSnap.hasData || deviceSnap.data == null) {
            return _buildStatusUI(
              deviceId: "N/A",
              location: "UNASSIGNED",
              gas: "N/A",
              flame: "N/A",
              temp: "N/A",
              sprinkler: "N/A",
            );
          }

          final deviceId = deviceSnap.data!;
          return StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('liveData').doc(deviceId).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snap.hasData || !snap.data!.exists) {
                return _buildStatusUI(
                  deviceId: deviceId,
                  location: "NO SIGNAL",
                  gas: "--",
                  flame: "--",
                  temp: "--",
                  sprinkler: "OFF",
                );
              }

              final data = snap.data!.data() as Map<String, dynamic>;
              final location = data['location'] ?? "Unknown Zone";
              final gas = data['gas'] != null ? "${data['gas']} PPM" : "--";
              final flame = data['flame'] == true ? "DETECTED" : "SAFE";
              final temp = data['temp'] != null ? "${data['temp']}°C" : "--";
              final sprinkler = data['sprinkler'] == true ? "ACTIVE" : "STANDBY";
              final bool isCritical = (data['flame'] == true) || (data['gas'] != null && data['gas'] > 1800);

              return _buildStatusUI(
                deviceId: deviceId,
                location: location,
                gas: gas,
                flame: flame,
                temp: temp,
                sprinkler: sprinkler,
                isCritical: isCritical,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusUI({
    required String deviceId,
    required String location,
    required String gas,
    required String flame,
    required String temp,
    required String sprinkler,
    bool isCritical = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isCritical ? const Color(0xFFD32F2F) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isCritical ? null : Border.all(color: const Color(0xFF003366), width: 2),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                Icon(
                  isCritical ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
                  size: 48,
                  color: isCritical ? Colors.white : const Color(0xFF003366),
                ),
                const SizedBox(height: 12),
                Text(
                  isCritical ? "CRITICAL UNIT STATUS" : "UNIT OPERATIONAL",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.white : const Color(0xFF003366),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "UNIT ID: $deviceId",
                  style: TextStyle(
                    color: isCritical ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "LIVE TELEMETRY",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          // Cards Grid
          Row(
            children: [
              Expanded(child: _buildMetricCard("GAS LEVEL", gas, Icons.gas_meter, gas != "--" && gas != "N/A" && int.tryParse(gas.split(' ')[0]) != null && int.parse(gas.split(' ')[0]) > 1800)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard("FLAME", flame, Icons.local_fire_department, flame == "DETECTED")),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard("TEMP", temp, Icons.thermostat, temp != "--" && temp != "N/A" && int.tryParse(temp.split('°')[0]) != null && int.parse(temp.split('°')[0]) > 50)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard("SPRINKLER", sprinkler, Icons.water_drop, sprinkler == "ACTIVE")),
            ],
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to settings (Placeholder)
              },
              icon: const Icon(Icons.settings),
              label: const Text("CONFIGURE UNIT PARAMETERS"),
              style: null, // Use Theme Defaults
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, bool isAlert) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFD32F2F) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: isAlert ? Colors.white : const Color(0xFF003366), size: 24),
              if (isAlert) const Icon(Icons.warning, color: Colors.white, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isAlert ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isAlert ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
