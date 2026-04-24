// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/services/notification_service.dart';
import 'ai_assistance_screen.dart';

class NeighborAlertScreen extends StatefulWidget {
  final String? alertId; // Optional: To open specific alert from notification
  const NeighborAlertScreen({super.key, this.alertId});

  @override
  State<NeighborAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<NeighborAlertScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = true;
  String? _societyName;
  String? _block;
  String? _userRole; // owner, manager, worker, supplier, fire_station

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserData();
    // Alarm is now triggered by the StreamBuilder only if data exists
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();

    if (data == null) return;

    setState(() {
      _societyName = data['buildingId']; // Matched with Backend & Screenshot
      _block = data['block'];
      _userRole = (data['role'] ?? 'worker').toString().toLowerCase();
    });
  }

  Future<void> _startAlarm() async {
    // Only play if allowed (unmuted) and not already playing
    if (!_isPlaying) return;
    
    // Check state to prevent restarting loop
    if (_player.state == PlayerState.playing) return;

    // Stop tray notification sound to avoid double audio
    await NotificationService().cancelAllNotifications();

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/alarm.mp3')); 
  }

  Future<void> _stopAlarm() async {
    await _player.stop();
    // Also stop the system notification sound/vibration
    await NotificationService().cancelAllNotifications();
  }

  void _toggleSound() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "N/A";
    return DateFormat('dd MMM • HH:mm').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("OFFICIAL EMERGENCY ALERT", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD50000), // Bright Red
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleSound,
            icon: Icon(_isPlaying ? Icons.notifications_active : Icons.notifications_off),
          ),
        ],
      ),
      body: (_societyName == null && widget.alertId == null)
          ? const Center(child: CircularProgressIndicator())
          : _buildAlertListener(),
    );
  }

  Widget _buildAlertListener() {
    // 1. If we have a specific Alert ID (from Notification), listen to THAT document
    if (widget.alertId != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('incidents').doc(widget.alertId).snapshots(),
        builder: (context, snap) {
           if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
           
           if (!snap.hasData || !snap.data!.exists) {
             _stopAlarm();
             return _buildNoAlertUI();
           }

           // Found specific alert
           _startAlarm();
           final alertData = snap.data!.data() as Map<String, dynamic>;
           return _buildMainContent(snap.data!.id, alertData);
        },
      );
    }

    // 2. Default Behavior: Listen for ANY active alert in my block
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('incidents') 
          .where('status', isEqualTo: 'active')
          .where('buildingId', isEqualTo: _societyName) 
          .where('block', isEqualTo: _block)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          _stopAlarm(); // Stop sound if no active alert
          return _buildNoAlertUI();
        }

        // Active Alert Found
        _startAlarm(); // Trigger sound

        final alert = snap.data!.docs.first;
        final alertData = alert.data() as Map<String, dynamic>;
        
        return _buildMainContent(alert.id, alertData);
      },
    );
  }

  Widget _buildMainContent(String alertId, Map<String, dynamic> alert) {
    // Fetch user details of who triggered it (optional, skipping for speed/cleanliness)
    final type = (alert['type'] ?? "FIRE").toString().toUpperCase();
    final time = _formatTime(alert['createdAt']);
    // Using 'house' from screenshot/model instead of 'flat'
    // Safety check: _societyName might be null if opened directly from notification deep link
    final safeSociety = _societyName ?? "PRAKH Gas Authority";
    final safeBlock = _block ?? (alert['block'] ?? '?');
    
    final location = "$safeSociety / BLOCK $safeBlock / UNIT ${alert['house'] ?? 'Unknown'}";

    return Column(
      children: [
        _buildHeader(type, time),
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildLocationCard(location, alert['flat'] ?? "Unknown"),
              
              const SizedBox(height: 16),
              
              // === DYNAMIC ROLE SCREEN ===
              _buildRoleSpecificInterface(type),
            ],
          ),
        ),

        _buildBottomActions(alertId, alert['victimPhone']),
      ],
    );
  }

  Widget _buildHeader(String type, String time) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFD50000),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.white),
          Text(
            type, 
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0)
          ),
          Text(
            "DETECTED AT $time",
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String fullLocation, String unit) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, color: Color(0xFFD50000), size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("INCIDENT LOCATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(fullLocation, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Sensor Node: Kitchen-Main-$unit", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ROLE SPECIFIC UI =================

  Widget _buildRoleSpecificInterface(String type) {
    final role = _userRole ?? 'worker';
    
    switch (role) {
      case 'supplier':
        return _buildGasSupplierView();
      case 'fire_station':
        return _buildFireStationView();
      case 'owner':
      case 'manager':
      case 'dept_head':
        return _buildCommandView();
      case 'worker':
      default:
        return _buildWorkerView();
    }
  }

  // 1. WORKER VIEW (Simplest, Exit Oriented)
  Widget _buildWorkerView() {
    return Column(
      children: [
        _buildInfoCard(
          "EVACUATION PROTOCOL",
          [
            _row("Route", "Use Staircase 2 (North Wing)", Icons.stairs),
            _row("Safe Zone", "Muster Point A (Car Park)", Icons.flag),
            _row("Do Not Use", "Elevators A & B Locked", Icons.elevator_outlined),
          ],
          Colors.orange.shade500,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: const Text(
            "INSTRUCTION: Leave belongings. Follow floor markings. Do not run.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  // 2. GAS SUPPLIER VIEW (Technical Data)
  Widget _buildGasSupplierView() {
    return Column(
      children: [
        _buildInfoCard(
          "SUPPLY LINE DIAGNOSTICS",
          [
            _row("Pipeline ID", "B-402 (Methane/LPG)", Icons.settings_input_component),
            _row("Valve No.", "V-20X (Auto-State: JAMMED)", Icons.adjust),
            _row("Pressure", "3200 PSI (CRITICAL HIGH)", Icons.speed),
            _row("Leak Rate", "450 PPM / sec", Icons.air),
          ],
          const Color(0xFF003366),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {}, 
            icon: const Icon(Icons.block),
            label: const Text("REMOTE CUT-OFF: VALVE V-20X"),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD50000), foregroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  // 3. FIRE STATION VIEW (Tactical Data)
  Widget _buildFireStationView() {
    return Column(
      children: [
        _buildInfoCard(
          "TACTICAL RESPONSE DATA",
          [
            _row("GPS Co-ords", "28.7041° N, 77.1025° E", Icons.gps_fixed),
            _row("Access Gate", "GATE 4 (Clearance: 12ft)", Icons.garage),
            _row("Hazmat Class", "CLASS C (Electrical/Gas)", Icons.science),
            _row("Nearest Hydrant", "HYD-04 (50m North)", Icons.water_drop),
          ],
          Colors.black87,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.map), label: const Text("OPEN MAP"))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.send), label: const Text("DISPATCH"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD50000), foregroundColor: Colors.white))),
          ],
        )
      ],
    );
  }

  // 4. COMMAND VIEW (Owner/Manager - Big Picture)
  Widget _buildCommandView() {
    // Fetch Live Data for Real-Time Monitoring
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('liveData').limit(1).snapshots(),
      builder: (context, snap) {
        int gas = 0;
        int temp = 0;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
           final data = snap.data!.docs.first.data() as Map<String, dynamic>;
           gas = data['gas'] ?? 0;
           temp = data['temp'] ?? 0;
        }

        return Column(
          children: [
            _buildInfoCard(
              "COMMAND CENTER OVERVIEW",
              [
                _row("Location", "PRAKH Gas Authority", Icons.location_city),
                _row("Active Threat", "Gas Leak Detected", Icons.warning),
                _row("Live Gas Level", "$gas % (CRITICAL)", Icons.cloud_circle),
                _row("Live Temperature", "$temp °C", Icons.thermostat),
              ],
              const Color(0xFF003366),
            ),
             const SizedBox(height: 16),
             // REMOVED GREEN BUTTON AS REQUESTED
          ],
        );
      },
    );
  }

  // ================= HELPERS =================

  Widget _buildInfoCard(String title, List<Widget> children, Color headerColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callReporter(String phone) async {
    // Sanitize phone number (remove spaces, dashes, etc.)
    final String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    debugPrint("📞 Attempting to call: '$phone' -> Cleaned: '$cleanPhone'");

    if (cleanPhone.isEmpty) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Invalid phone number")),
            );
        }
        return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
        debugPrint("Could not launch dialer for $cleanPhone");
        // Fallback: Just print error, user might have no dialer app?
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Could not open phone dialer")),
            );
        }
      }
    } catch (e) {
      debugPrint("Error calling reporter: $e");
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e")),
          );
      }
    }
  }

  Widget _buildBottomActions(String alertId, String? phone) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Call 101 Button (Full Width)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _callReporter("101"),
              icon: const Icon(Icons.local_fire_department, color: Colors.orange),
              label: const Text("CALL 101 (FIRE)", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 2. Mark Safe Button
           SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _resolveAlert(alertId),
              icon: const Icon(Icons.notifications_off),
              label: const Text("STOP ALARM & MARK SAFE", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD50000), 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveAlert(String alertId) async {
    await _player.stop();
    await _firestore.collection('incidents').doc(alertId).update({"status": "resolved"});
    await NotificationService().cancelAllNotifications();
    if (mounted) {
      // Navigate to AI Assistance Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AiAssistanceScreen()),
      );
    }
  }

  Widget _buildNoAlertUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 80, color: Colors.green.shade200),
          const SizedBox(height: 20),
          Text("All Systems Normal", style: TextStyle(fontSize: 22, color: Colors.grey[700], fontWeight: FontWeight.bold)),
          Text("No active threats in ${_societyName ?? 'Sector'}", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
