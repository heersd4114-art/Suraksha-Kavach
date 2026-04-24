import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:audioplayers/audioplayers.dart';

class VictimAlertScreen extends StatefulWidget {
  final String alertId;

  const VictimAlertScreen({super.key, required this.alertId});

  @override
  State<VictimAlertScreen> createState() => _VictimAlertScreenState();
}

class _VictimAlertScreenState extends State<VictimAlertScreen> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playSiren();
  }

  Future<void> _playSiren() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Assuming 'alarm.mp3' based on common naming, will correct if list_dir shows otherwise
      await _player.play(AssetSource('sounds/alarm.mp3')); 
    } catch (e) {
      debugPrint("Siren Error: $e");
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Alert"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection('alerts').doc(widget.alertId).snapshots(),

        builder: (context, alertSnap) {
          if (!alertSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!alertSnap.data!.exists) {
            return const Center(child: Text("Alert not found"));
          }

          final alert = alertSnap.data!.data() as Map<String, dynamic>;

          final victimUid = alert['uid']; // Changed from 'victimUid' based on models.py 'uid'

          return StreamBuilder<DocumentSnapshot>(
            stream: firestore.collection('users').doc(victimUid).snapshots(),

            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final user = userSnap.data!.data() as Map<String, dynamic>;

              return _buildUI(context, alert, user);
            },
          );
        },
      ),
    );
  }

  // ================= UI =================

  Widget _buildUI(
    BuildContext context,
    Map<String, dynamic> alert,
    Map<String, dynamic> user,
  ) {
    final name = user['name'] ?? "N/A";
    final phone = user['phone'] ?? "N/A";

    final flat = alert['flatnumber'] ?? "N/A";
    final type = alert['type'] ?? "Fire";
    final society = alert['societyName'] ?? "N/A";
    final block = alert['block'] ?? "N/A";

    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.red.shade50,

          child: Row(
            children: const [
              Icon(Icons.warning, color: Colors.red, size: 28),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  "FIRE EMERGENCY DETECTED",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Details
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),

            children: [
              _item("Victim", name),
              _item("Phone", phone),
              _item("Society", society),
              _item("Block", block),
              _item("Flat", flat),
              _item("Emergency Type", type),
              _item("Status", alert['status']),
            ],
          ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.all(16),

          child: Row(
            children: [
              // Call
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: phone == "N/A"
                      ? null
                      : () async {
                          final url = Uri.parse("tel:+91$phone");

                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },

                  icon: const Icon(Icons.call),
                  label: const Text("Call"),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Resolve
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('alerts')
                        .doc(widget.alertId)
                        .update({
                          "status": "resolved",
                          "resolvedAt": FieldValue.serverTimestamp(),
                        });

                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },

                  icon: const Icon(Icons.check),
                  label: const Text("Resolved"),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= ITEM =================

  Widget _item(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
