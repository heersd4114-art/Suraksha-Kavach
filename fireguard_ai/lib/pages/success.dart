import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  final String message; // The custom success text to show
  final VoidCallback onPressed; // What happens when they click the button
  final String
  buttonText; // Optional: text for the button (default is "Continue")

  const SuccessScreen({
    super.key,
    required this.message,
    required this.onPressed,
    this.buttonText = "Continue",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Large Animated-style Icon
            const Icon(
              Icons.check_circle,
              color: Colors.green, // Green is universal for success
              size: 100,
            ),

            const SizedBox(height: 30),

            // 2. "Success!" Title
            const Text(
              "Success!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10),

            // 3. The Custom Message (Passed from previous screen)
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const SizedBox(height: 50),

            // 4. Action Button (Matches your Orange Theme)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(buttonText, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
