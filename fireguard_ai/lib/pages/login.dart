import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'register_screen.dart';
import 'forgot_password.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // ---------------- SESSION SAVE ----------------

  Future<void> _saveLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  // ---------------- LOGIN ----------------

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _saveLoginSession();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Authentication failed");
    } catch (_) {
      _showMessage("Unexpected error occurred");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------- MESSAGE ----------------

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Section
                const Icon(
                  Icons.shield_outlined,
                  size: 80,
                  color: Color(0xFF003366), // Navy
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  "SURAKSHA KAVACH",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto Slab',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366), // Navy
                    letterSpacing: 1.5,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  "SECURE AUTHENTICATION",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 2.0,
                  ),
                ),

                const SizedBox(height: 48),

                // Email
                _buildField(
                  label: "OFFICIAL ID / EMAIL",
                  icon: Icons.person_outline,
                  controller: _emailController,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "ID required";
                    if (!v.contains('@')) return "Invalid format";
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                _buildField(
                  label: "PASSWORD",
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  obscure: true,
                  validator: (v) {
                    if (v == null || v.length < 6) return "Min 6 chars";
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF003366),
                    ),
                    child: const Text("Reset Password?"),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginUser,
                    // style handled by Theme
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white, // White against Saffron
                            ),
                          )
                        : const Text(
                            "ACCESS COMMAND CENTER",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OR", style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Register
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    // style handled by Theme
                    child: const Text(
                      "NEW REGISTRATION",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
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

  // ---------------- INPUT FIELD ----------------

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF003366)), // Navy Input Text
      decoration: InputDecoration(
        labelText: label,
        hintText: "Enter your ${label.toLowerCase()}", // Added proper hint
        prefixIcon: Icon(icon), // Color handled by Theme
        // Theme handles borders and fill now
      ),
    );
  }
}
