import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailCtrl = TextEditingController();

  final TextEditingController _passwordCtrl = TextEditingController();

  final TextEditingController _confirmCtrl = TextEditingController();

  bool _emailVerified = false;
  bool _loading = false;

  // ---------------- Send Verification Link ----------------

  Future<void> _sendVerificationLink() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showMessage("Enter your email first");
      return;
    }

    final user = _auth.currentUser;

    if (user == null || user.email != email) {
      _showMessage("Email does not match your account");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);

      _showMessage("Verification link sent to your email");
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Failed to send email");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // ---------------- Check Email Verified ----------------

  Future<void> _checkVerification() async {
    final user = _auth.currentUser;

    if (user == null) return;

    await user.reload();

    setState(() {
      _emailVerified = true;
    });

    _showMessage("Email verified successfully");
  }

  // ---------------- Change Password ----------------

  Future<void> _changePassword() async {
    final pass = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (!_emailVerified) {
      _showMessage("Verify your email first");
      return;
    }

    if (pass.isEmpty || confirm.isEmpty) {
      _showMessage("Enter all fields");
      return;
    }

    if (pass.length < 6) {
      _showMessage("Password must be 6+ characters");
      return;
    }

    if (pass != confirm) {
      _showMessage("Passwords do not match");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user = _auth.currentUser;

      if (user == null) return;

      await user.updatePassword(pass);

      await _auth.signOut();

      if (!mounted) return;

      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Update failed");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // ---------------- Success Dialog ----------------

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (context) {
        return AlertDialog(
          title: const Text("Password Updated"),

          content: const Text(
            "Your password has been changed successfully.\n\nPlease login again.",
          ),

          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },

              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ---------------- Snackbar ----------------

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.deepOrange),

            const SizedBox(height: 15),

            const Text(
              "Secure Password Reset",

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            // Email
            TextField(
              controller: _emailCtrl,

              keyboardType: TextInputType.emailAddress,

              decoration: const InputDecoration(
                labelText: "Registered Email",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // Send link
            SizedBox(
              width: double.infinity,
              height: 45,

              child: ElevatedButton(
                onPressed: _loading ? null : _sendVerificationLink,

                child: const Text("Send Verification Link"),
              ),
            ),

            const SizedBox(height: 15),

            // Verify
            SizedBox(
              width: double.infinity,
              height: 45,

              child: OutlinedButton(
                onPressed: _checkVerification,

                child: const Text("I Have Verified"),
              ),
            ),

            const SizedBox(height: 25),

            // New Password
            TextField(
              controller: _passwordCtrl,
              obscureText: true,

              enabled: _emailVerified,

              decoration: const InputDecoration(
                labelText: "New Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // Confirm
            TextField(
              controller: _confirmCtrl,
              obscureText: true,

              enabled: _emailVerified,

              decoration: const InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            // Update Button
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: _loading ? null : _changePassword,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),

                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "UPDATE PASSWORD",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
