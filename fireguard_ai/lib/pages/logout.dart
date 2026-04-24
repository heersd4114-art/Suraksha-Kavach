import 'package:flutter/material.dart';
import 'login.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD), // Soft Blue
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF003366).withValues(alpha: 0.2), width: 2),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 80,
                  color: Color(0xFF003366), // Navy
                ),
              ),

              const SizedBox(height: 30),

              // 2. Title
              const Text(
                "SHIFT ENDED",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              // 3. Subtitle
              Text(
                "You have successfully logged out of the\nSuraksha Kavach Network.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 50),

              // 4. Return to Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text(
                    "RETURN TO DUTY (LOGIN)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00), // Saffron
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                "Security Systems Remain Active 24/7",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            ],
          ),
        ),
      ),
    );
  }
}
