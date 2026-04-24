// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'alert_notifications_screen.dart';
import 'device_status_screen.dart';
import 'safety_tips_screen.dart';
import 'ai_assistance_screen.dart';
import 'logout.dart';
import 'profile.dart';
import 'neighbour_alert.dart';
import 'alert_listener_screen.dart';
import 'staff_directory_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  bool _popupShown = false;
  bool _wasAlert = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _alertBannerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _alertBannerAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for status indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Alert banner flash animation
    _alertBannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _alertBannerAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _alertBannerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _alertBannerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- Role-Based Logic ----------------

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  void _showNoDevicePopup() {
    if (_popupShown) return;
    _popupShown = true;
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Device Status"),
            content: const Text(
              "No SURAKSHA Device Linked.\n\nPlease connect a hardware unit to activate live monitoring.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ACKNOWLEDGE"),
              ),
            ],
          );
        },
      );
    });
  }

  void _onAlertStateChanged(bool isAlert) {
    if (isAlert && !_wasAlert) {
      // Alert just triggered - haptic feedback and auto-scroll
      HapticFeedback.heavyImpact();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut);
      }
    }
    _wasAlert = isAlert;
  }

  @override
  Widget build(BuildContext context) {
    return AlertListenerWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SURAKSHA COMMAND"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NeighborAlertScreen())),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _getUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = snapshot.data;
              if (userData == null) {
                return const Center(child: Text("Profile Error"));
              }

              final String role =
                  (userData['role'] ?? 'staff').toString().toUpperCase();
              final String? deviceId =
                  userData['deviceId'] ?? 'VAYUSHURAKSHA: #GD&L 1';
              final String? block = userData['block'];
              final String userName = userData['name'] ?? 'Suraksha Officer';
              final String userEmail =
                  _auth.currentUser?.email ?? 'ID: 8820-ALPHA';

              return _buildUnifiedView(
                  context, role, deviceId, block, userName, userEmail);
            },
          ),
        ),
      ),
    );
  }

  // ---------------- UNIFIED VIEW ----------------
  Widget _buildUnifiedView(BuildContext context, String role, String? deviceId,
      String? block, String userName, String userEmail) {
    return StreamBuilder<DocumentSnapshot>(
      stream: (deviceId != null)
          ? _firestore.collection('liveData').doc(deviceId).snapshots()
          : null,
      builder: (context, snap) {
        // Default Values
        int? gas;
        bool? flame;
        int? temp;
        bool? sprinkler;
        bool alert = false;
        DateTime? lastUpdated;

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          gas = data['gas'];
          flame = data['flame'];
          temp = data['temp'];
          sprinkler = data['sprinkler'];
          // Get last updated timestamp
          if (data['timestamp'] != null) {
            lastUpdated = (data['timestamp'] as Timestamp).toDate();
          }
        }

        // Auto-Alert Logic
        final bool isSprinklerActive = (sprinkler == true);
        alert = (gas != null && gas > 30) || (flame == true);

        // Trigger haptic + scroll on alert state change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onAlertStateChanged(alert);
        });

        return RefreshIndicator(
          color: const Color(0xFFFF9933),
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 1. Status Header with Pulse
                _buildStatusHeader(
                    "${role.replaceAll('_', ' ')} COMMAND", !alert),

                const SizedBox(height: 8),

                // Live connection indicator
                _buildConnectionIndicator(snap.connectionState, lastUpdated),

                const SizedBox(height: 12),

                // 2. Emergency Alert Banner (animated)
                if (alert) _buildEmergencyBanner(),

                // 3. ESP32 Dynamic Metric Cards
                if (deviceId == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: Colors.orange.shade50,
                      child: const ListTile(
                        leading: Icon(Icons.link_off, color: Colors.orange),
                        title: Text("No Device Linked"),
                        subtitle:
                            Text("Contact admin to link a sensor unit."),
                      ),
                    ),
                  )
                else
                  _buildDynamicGaugesGrid(
                      context, gas, flame, temp, isSprinklerActive, alert),

                const SizedBox(height: 20),

                // 4. Recent Alert History
                _buildSectionHeader("RECENT ALERTS (${block ?? 'ALL'})"),
                _buildAlertHistory(block, role),

                const SizedBox(height: 20),

                // 5. Quick Actions
                _buildSectionHeader("QUICK ACTIONS"),
                _buildQuickActions(context, role),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- CONNECTION INDICATOR ----------------
  Widget _buildConnectionIndicator(
      ConnectionState state, DateTime? lastUpdated) {
    final bool isConnected = state == ConnectionState.active;
    String timeText = "Waiting for data...";
    if (lastUpdated != null) {
      final diff = DateTime.now().difference(lastUpdated);
      if (diff.inSeconds < 10) {
        timeText = "Live • Just now";
      } else if (diff.inMinutes < 1) {
        timeText = "Live • ${diff.inSeconds}s ago";
      } else if (diff.inHours < 1) {
        timeText = "Updated ${diff.inMinutes}m ago";
      } else {
        timeText = "Last seen ${diff.inHours}h ago";
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected
                    ? Colors.green.withValues(alpha: _pulseAnimation.value)
                    : Colors.orange,
                boxShadow: isConnected
                    ? [
                        BoxShadow(
                          color:
                              Colors.green.withValues(alpha: _pulseAnimation.value * 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(Icons.sensors, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text("ESP32",
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---------------- EMERGENCY BANNER ----------------
  Widget _buildEmergencyBanner() {
    return AnimatedBuilder(
      animation: _alertBannerAnimation,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFD32F2F)
                  .withValues(alpha: _alertBannerAnimation.value),
              const Color(0xFFFF5252)
                  .withValues(alpha: _alertBannerAnimation.value),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(
                  _alertBannerAnimation.value * 0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 600),
              builder: (_, scale, child) => Transform.scale(
                scale: _alertBannerAnimation.value * 0.4 + 0.8,
                child: child,
              ),
              child:
                  const Icon(Icons.sos, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "EMERGENCY ALERT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Threat detected • Immediate action required",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- DYNAMIC ESP32 GAUGES ----------------
  Widget _buildDynamicGaugesGrid(BuildContext context, int? gas, bool? flame,
      int? temp, bool isSprinklerActive, bool alert) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Gas + Flame
          Row(
            children: [
              Expanded(
                child: _buildGasCard(gas),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFlameCard(flame),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Temperature + Sprinkler
          Row(
            children: [
              Expanded(
                child: _buildTemperatureCard(temp),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSprinklerCard(isSprinklerActive),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // AI Assist Button
          _buildAiAssistButton(context),
        ],
      ),
    );
  }

  // --- GAS LEVEL CARD ---
  Widget _buildGasCard(int? gas) {
    final int value = gas ?? 0;
    final double percentage = (value / 100).clamp(0.0, 1.0);
    final bool isCritical = value > 30;
    final bool isWarning = value > 20;

    Color getColor() {
      if (isCritical) return const Color(0xFFD32F2F);
      if (isWarning) return const Color(0xFFFF8F00);
      return const Color(0xFF43A047);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical
            ? const Color(0xFFFFEBEE)
            : isWarning
                ? const Color(0xFFFFF8E1)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: getColor().withValues(alpha: 0.4),
          width: isCritical ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCritical
                ? Colors.red.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isCritical ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.gas_meter_rounded, color: getColor(), size: 20),
              if (isCritical)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red
                          .withValues(alpha: _pulseAnimation.value * 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("HIGH",
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            gas == null ? "--" : "$value%",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: getColor(),
            ),
          ),
          const SizedBox(height: 4),
          const Text("GAS LEVEL",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              height: 6,
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(getColor()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FLAME STATUS CARD ---
  Widget _buildFlameCard(bool? flame) {
    final bool detected = flame == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: detected ? const Color(0xFFFFEBEE) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              detected ? Colors.red.withValues(alpha: 0.5) : Colors.grey.shade300,
          width: detected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: detected
                ? Colors.red.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: detected ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Transform.scale(
                  scale: detected ? (_pulseAnimation.value * 0.3 + 0.85) : 1.0,
                  child: Icon(
                    detected ? Icons.local_fire_department : Icons.shield,
                    color: detected
                        ? Colors.deepOrange
                        : const Color(0xFF43A047),
                    size: 22,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: detected
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detected ? "⚠ ALERT" : "✓ OK",
                  style: TextStyle(
                    color: detected ? Colors.red : Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detected ? "DETECTED" : "CLEAR",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: detected ? Colors.red : const Color(0xFF43A047),
            ),
          ),
          const SizedBox(height: 4),
          const Text("FLAME STATUS",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          // Status bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: detected ? Colors.red : const Color(0xFF43A047),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TEMPERATURE CARD ---
  Widget _buildTemperatureCard(int? temp) {
    final int value = temp ?? 0;
    final double percentage = (value / 100).clamp(0.0, 1.0);
    final bool isCritical = value > 50;
    final bool isWarm = value > 30;

    Color getColor() {
      if (isCritical) return const Color(0xFFD32F2F);
      if (isWarm) return const Color(0xFFFF8F00);
      return const Color(0xFF1E88E5);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical
            ? const Color(0xFFFFEBEE)
            : isWarm
                ? const Color(0xFFFFF8E1)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: getColor().withValues(alpha: 0.4),
          width: isCritical ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCritical
                ? Colors.red.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isCritical ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.thermostat_rounded, color: getColor(), size: 20),
              if (isCritical)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red
                          .withValues(alpha: _pulseAnimation.value * 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("HOT",
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            temp == null ? "--" : "$value°C",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: getColor(),
            ),
          ),
          const SizedBox(height: 4),
          const Text("TEMPERATURE",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          // Gradient progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              height: 6,
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(getColor()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SPRINKLER STATUS CARD ---
  Widget _buildSprinklerCard(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isActive ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Transform.scale(
                  scale: isActive ? (_pulseAnimation.value * 0.2 + 0.9) : 1.0,
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: isActive
                        ? const Color(0xFF1E88E5)
                        : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? "💧 ON" : "IDLE",
                  style: TextStyle(
                    color: isActive ? Colors.blue : Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isActive ? "ACTIVE" : "STANDBY",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isActive ? const Color(0xFF1E88E5) : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          const Text("SPRINKLER",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          // Status bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1E88E5) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- AI ASSIST BUTTON ---
  Widget _buildAiAssistButton(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFF003366),
      elevation: 4,
      shadowColor: const Color(0xFF003366).withValues(alpha: 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AiAssistanceScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          width: double.infinity,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                "RAKSHAK AI ASSIST",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertHistory(String? block, String role) {
    Query query = _firestore
        .collection('incidents')
        .orderBy('createdAt', descending: true)
        .limit(5);

    if (role != 'OWNER' && block != null) {
      query = query.where('block', isEqualTo: block);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(Icons.verified_user, size: 40, color: Colors.green.shade200),
                const SizedBox(height: 8),
                const Text("No recent alerts",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, index) {
            final data =
                snap.data!.docs[index].data() as Map<String, dynamic>;
            final type = data['type'] ?? 'ALERT';
            final timestamp = (data['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final timeStr =
                "${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
            final status = data['status'] ?? 'active';
            final isResolved = status == 'resolved';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: isResolved
                        ? Colors.green.shade200
                        : Colors.red.shade200),
              ),
              color: isResolved ? Colors.green.shade50 : Colors.red.shade50,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isResolved
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: isResolved ? Colors.green : Colors.red,
                    size: 22,
                  ),
                ),
                title: Text("$type - Unit ${data['house'] ?? '?'}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(
                    "${status.toString().toUpperCase()} • $timeStr",
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
                trailing:
                    const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => NeighborAlertScreen(
                            alertId: snap.data!.docs[index].id))),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, String role) {
    return Column(
      children: [
        if (role == 'OWNER')
          _buildListItem(context, "Staff Directory", Icons.people_alt,
              const StaffDirectoryScreen()),
        _buildListItem(context, "Notify Neighbors", Icons.campaign,
            const NotifyNeighborsScreen()),
        _buildListItem(context, "Safety Protocols", Icons.menu_book,
            const SafetyTipsScreen()),
      ],
    );
  }

  // ---------------- REUSED COMPONENTS ----------------

  Widget _buildStatusHeader(String title, bool systemSecure) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: systemSecure
              ? [const Color(0xFF003366), const Color(0xFF004C99)]
              : [const Color(0xFF8B0000), const Color(0xFFD32F2F)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
              color: (systemSecure ? const Color(0xFF003366) : Colors.red)
                  .withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: systemSecure
                        ? Colors.greenAccent
                            .withValues(alpha: _pulseAnimation.value)
                        : Colors.redAccent
                            .withValues(alpha: _pulseAnimation.value),
                    boxShadow: [
                      BoxShadow(
                        color: (systemSecure
                                ? Colors.greenAccent
                                : Colors.redAccent)
                            .withValues(alpha: _pulseAnimation.value * 0.6),
                        blurRadius: 8,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                systemSecure ? "STATUS: SECURE" : "STATUS: CRITICAL",
                style: TextStyle(
                  color: systemSecure ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Sub-Widgets ----------------

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildListItem(
      BuildContext context, String title, IconData icon, Widget page) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFFFF9933), size: 20),
        ),
        title: Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final name = data?['name'] ?? 'Suraksha Officer';
          final email = _auth.currentUser?.email ?? 'ID: 8820-ALPHA';
          final role = (data?['role'] ?? 'staff').toString().toUpperCase();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Row(
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                accountEmail: Text(email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Color(0xFF003366),
                    ),
                  ),
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003366), Color(0xFF004C99)],
                  ),
                ),
              ),
              _drawerItem(
                  "Command Center", const DashboardScreen(), Icons.dashboard),
              _drawerItem(
                  "Profile & ID", const UserProfileScreen(), Icons.badge),
              _drawerItem(
                  "Device Status", const DeviceStatusScreen(), Icons.router),
              const Divider(),
              _drawerItem(
                  "Protocols", const SafetyTipsScreen(), Icons.library_books),
              _drawerItem(
                  "Logout", const LogoutScreen(), Icons.exit_to_app),
            ],
          );
        },
      ),
    );
  }

  Widget _drawerItem(String title, Widget page, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF003366)),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
