// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'ai_assistance_screen.dart'; // To redirect after stopping

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // 1. Setup Pulse Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.9,
      upperBound: 1.2,
    )..repeat(reverse: true);

    // 2. Play Sound
    _playAlarmSound();
  }

  void _playAlarmSound() async {
    // Sets the player to loop indefinitely
    await _player.setReleaseMode(ReleaseMode.loop);

    // PLAYING SOUND:
    // Make sure 'alarm.mp3' is in your 'assets/sounds/' folder!
    // If you don't have a file yet, use this online URL line instead for testing:
    // await _player.play(UrlSource('https://www.soundjay.com/mechanical/sounds/smoke-detector-1.mp3'));

    await _player.play(AssetSource('sounds/alarm.mp3'));
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _stopAlarmAndRedirect() {
    _player.stop(); // Stop noise immediately

    // Redirect to AI Assistance
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AiAssistanceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Use Deep Orange background for high alert visibility
      backgroundColor: Colors.deepOrange,
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.deepOrange, // Matches background
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: const [],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- WHITE CARD FOR CONTENT ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // --- TITLE ---
                  const Text(
                    "CRITICAL FIRE ALERT EVACUATE NOW",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Colors.deepOrange, // Theme color
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "FIRE / GAS LEAK DETECTED!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- ANIMATED BELL ICON ---
                  ScaleTransition(
                    scale: _controller,
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepOrange.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.deepOrange, width: 2),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        size: 100,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    "Loud Alarm Activated!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- STOP BUTTON ---
            SizedBox(
              width: 350,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _stopAlarmAndRedirect,
                icon: const Icon(Icons.volume_off, color: Colors.deepOrange),
                label: const Text(
                  "STOP ALARM AND GET HELP",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.white, // White button on Orange background
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
