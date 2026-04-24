import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailCtrl = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  // ---------------- RESET PASSWORD ----------------

  Future<void> _sendResetLink() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showMessage("Please enter your email");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _showMessage("Password reset link sent to your email");

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Failed to send reset link");
    } catch (e) {
      _showMessage("Something went wrong");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ---------------- MESSAGE ----------------

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Colors.deepOrange,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Forgot Password?",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Text(
                  "Enter your registered email to receive reset link",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),

                const SizedBox(height: 30),

                // Email
                TextField(
                  controller: _emailCtrl,

                  keyboardType: TextInputType.emailAddress,

                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    filled: true,
                  ),
                ),

                const SizedBox(height: 25),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetLink,

                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            "Send Reset Link",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
