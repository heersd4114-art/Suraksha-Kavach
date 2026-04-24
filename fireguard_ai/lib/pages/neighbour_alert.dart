import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'success.dart';

class NotifyNeighborsScreen extends StatefulWidget {
  const NotifyNeighborsScreen({super.key});

  @override
  State<NotifyNeighborsScreen> createState() => _NotifyNeighborsScreenState();
}

class _NotifyNeighborsScreenState extends State<NotifyNeighborsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _neighbors = [];

  bool _isSelectAll = false;
  bool _loading = true;

  // Society Info
  String? _societyName;
  String? _blockName;
  String? _chairman;
  String? _secretary;

  @override
  void initState() {
    super.initState();
    _loadNeighbors();
  }

  // ================= LOAD DATA =================

  Future<void> _loadNeighbors() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        _stopLoading();
        return;
      }

      // Get current user
      final myDoc = await _firestore.collection('users').doc(user.uid).get();

      final myData = myDoc.data();

      if (myData == null) {
        _stopLoading();
        return;
      }

      final society = myData['society'];

      // Extract society info
      _societyName = society?['name'];
      _blockName = society?['block'];
      _chairman = society?['chairman'];
      _secretary = society?['secretary'];

      if (_societyName == null || _blockName == null) {
        debugPrint("Missing society/block info");
        _stopLoading();
        return;
      }

      // Query neighbors
      final snapshot = await _firestore
          .collection('users')
          .where('society.name', isEqualTo: _societyName)
          .where('society.block', isEqualTo: _blockName)
          .get();

      final List<Map<String, dynamic>> temp = [];

      for (var doc in snapshot.docs) {
        if (doc.id == user.uid) continue;

        final data = doc.data();

        temp.add({
          "uid": doc.id,
          "name": data['name'] ?? "Unknown",
          "flat": data['society']?['flat'] ?? "N/A",
          "phone": data['phone'] ?? "N/A",
          "isSelected": false,
        });
      }

      setState(() {
        _neighbors = temp;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Load error: $e");
      _stopLoading();
    }
  }

  void _stopLoading() {
    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  // ================= SELECT ALL =================

  void _toggleSelectAll(bool? value) {
    final select = value ?? false;

    setState(() {
      _isSelectAll = select;

      for (var n in _neighbors) {
        n['isSelected'] = select;
      }
    });
  }

  // ================= UI =================

  @override
  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("ZONE BROADCAST", style: TextStyle(letterSpacing: 1.2)),
        backgroundColor: const Color(0xFFD32F2F), // Red for Alert Broadcast
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: _neighbors.isEmpty ? _buildEmptyUI() : _buildList(),
                ),

                _buildBottomSection(),
              ],
            ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SELECT RECIPIENTS",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_societyName != null && _blockName != null)
                    Text(
                      "FACTORY: $_societyName • ZONE: $_blockName",
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                ],
              ),

              Row(
                children: [
                  const Text("SELECT ALL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Checkbox(
                    value: _isSelectAll,
                    activeColor: const Color(0xFFD32F2F),
                    onChanged: _toggleSelectAll,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Authority Panel
          if (_chairman != null || _secretary != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0), // Light Orange
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFF9933).withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: Color(0xFFE65100)),
                      SizedBox(width: 8),
                      Text(
                        "ZONE COMMANDERS",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFFE65100),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_chairman != null) Text("• $_chairman (Chief Safety Officer)", style: const TextStyle(fontSize: 13)),
                  if (_secretary != null) Text("• $_secretary (Zone Manager)", style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ================= EMPTY =================

  Widget _buildEmptyUI() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.domain_disabled, size: 60, color: Colors.grey),
            SizedBox(height: 15),
            Text(
              "NO ACTIVE UNITS",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "No units or personnel registered in this zone.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LIST =================

  Widget _buildList() {
    return ListView.separated(
      itemCount: _neighbors.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final n = _neighbors[index];
        return CheckboxListTile(
          activeColor: const Color(0xFFD32F2F),
          title: Text(
            n['name'],
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF003366)),
          ),
          subtitle: Text("Designation: ${n['flat']}", style: const TextStyle(fontSize: 12)), // Flat -> Designation/Unit
          secondary: CircleAvatar(
            backgroundColor: const Color(0xFF003366),
            child: Text(
              n['flat'].toString().isNotEmpty ? n['flat'][0] : "U",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          value: n['isSelected'],
          onChanged: (value) {
            setState(() {
              n['isSelected'] = value;
              _isSelectAll = _neighbors.every((x) => x['isSelected']);
            });
          },
        );
      },
    );
  }

  // ================= BOTTOM =================

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE), // Red 50
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "WARNING: This action will trigger a high-priority alert to all selected units.",
                    style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Button
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _sendAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F), // Red
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              icon: const Icon(Icons.campaign),
              label: const Text(
                "INITIATE ALERT BROADCAST",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SEND =================

  void _sendAlert() {
    final selected = _neighbors.where((n) => n['isSelected']).toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one neighbor")),
      );
      return;
    }

    Navigator.pushReplacement(
      context,

      MaterialPageRoute(
        builder: (_) => SuccessScreen(
          message: "Emergency Alert Sent Successfully!",
          onPressed: () => Navigator.pop(context),
          buttonText: "Return to Dashboard",
        ),
      ),
    );
  }
}
