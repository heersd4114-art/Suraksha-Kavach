import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

import 'victim_alert_screen.dart';



class AlertListenerWrapper extends StatefulWidget {
  final Widget child;
  const AlertListenerWrapper({super.key, required this.child});

  @override
  State<AlertListenerWrapper> createState() => _AlertListenerWrapperState();
}

class _AlertListenerWrapperState extends State<AlertListenerWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _society;
  String? _block;
  String? _lastAlertId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      if (!mounted) return;

      setState(() {
        // Try new nested structure first, fallback to legacy top-level fields
        final societyMap = data['society'] as Map<String, dynamic>?;
        
        if (societyMap != null) {
           _society = societyMap['name'];
           _block = societyMap['block'];
        } else {
           _society = data['buildingId']; // Legacy field
           _block = data['block'];         // Legacy field
        }
      });
      
      debugPrint("Listener Active: Society=$_society, Block=$_block");

      // --- NEW: Register for Notifications ---
      // This ensures the backend has the latest token to send alerts to.
      try {
        await NotificationService().init();
      } catch (e) {
        debugPrint("Notification Init Failed: $e");
      }

    } catch (e) {
      debugPrint("User load error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. If we don't know the location yet, just show the app
    if (_society == null || _block == null) {
      // debugPrint("Listener Inactive: Missing location data"); 
      return widget.child;
    }

    // 2. Listen for alerts overlays
    return Stack(
      children: [
        widget.child,
        
        // Background Listener
        Positioned.fill(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('alerts')
                .where('status', isEqualTo: 'active')
                .where('societyName', isEqualTo: _society)
                .where('block', isEqualTo: _block)
                .limit(1)
                .snapshots(),
            
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                _lastAlertId = null; 
                return const SizedBox.shrink(); // Invisible
              }

              final alertDoc = snapshot.data!.docs.first;
              final alertId = alertDoc.id;

              // Found an active alert!
              if (_lastAlertId != alertId) {
                _lastAlertId = alertId;
                
                // Navigate immediately
                WidgetsBinding.instance.addPostFrameCallback((_) {
                   if (!mounted) return;
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (_) => VictimAlertScreen(alertId: alertId),
                     ),
                   );
                });
              }

              return const SizedBox.shrink(); // Still invisible, just logic
            },
          ),
        ),
      ],
    );
  }
}
