import 'dart:async';
import 'package:flutter/material.dart';

import 'login.dart';
import 'dashboard_screen.dart';
import 'alert_notifications_screen.dart'; // Ensure this matches actual file
import '../core/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;

  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fade = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scale = Tween(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Navigate after splash
    Timer(const Duration(seconds: 3), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;
    
    // Check for pending notification launch
    if (NotificationService().pendingAlertId != null) {
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Pass the ID to the alert screen
          builder: (_) => NeighborAlertScreen(alertId: NotificationService().pendingAlertId),
        ),
      );
      NotificationService().pendingAlertId = null; // Clear it
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            widget.isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    // Government/Official Vibe: Solid Navy or Dark Gradient
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF003366), Color(0xFF001A33)], // Navy Gradients
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, _) {
              return Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: _buildContent(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------- CONTENT ----------------

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Saffron Shield / emblem wrapper
        // Logo Asset
        Image.asset(
          'assets/images/icon(2).png',
          width: 120,
          height: 120,
        ),

        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9933), // Saffron Orange
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9933).withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            "SURAKSHA KAVACH",
            style: TextStyle(
              fontFamily: 'Roboto Slab',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "SATARK. SURAKSHIT.", // Tagline
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFB0BEC5), // Light Grey
            letterSpacing: 3.0,
          ),
        ),

        const SizedBox(height: 50),

        const CircularProgressIndicator(
          color: Color(0xFFFF9933), // Saffron loader
          strokeWidth: 2,
        ),
        
        const SizedBox(height: 20),
        
        const Text(
          "Initializing Protocols...",
          style: TextStyle(
            fontSize: 12,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
