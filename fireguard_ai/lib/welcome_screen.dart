import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import HomeScreen to navigate to it

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // This timer waits for 3 seconds, then goes to the next page
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background as requested
      body: Center(
            // Suraksha Kavach Logo Placeholder
            // Image.asset(
            //   'assets/images/logo.png', // Will use this once generated
            //   width: 150,
            //   height: 150,
            // ),
            // const SizedBox(height: 20),
            child: const Text(
              "SURAKSHA KAVACH",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black, 
              ),
            ),
      ),
    );
  }
}
