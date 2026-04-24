import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Role Selection
  String _selectedRole = 'employee'; // Default
  final List<String> _roles = ['owner', 'manager', 'dept_head', 'employee'];

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  // Animation
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Setup animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    // Start animation
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();

    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ---------------- REGISTER ----------------

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showMessage("Please fill all fields");
      return;
    }

    if (password.length < 6) {
      _showMessage("Password must be at least 6 characters");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Save user with selected role to Firestore
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': _selectedRole, // Use selected role
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      _showMessage("Registration successful. Please login.");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      _showMessage("Registration failed: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ---------------- MESSAGE ----------------

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("OFFICIAL REGISTRATION"),
        backgroundColor: const Color(0xFF003366), // Navy
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ---------- ANIMATED HEADER ----------
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.shield,
                        size: 80,
                        color: Color(0xFF003366), // Navy
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "SURAKSHA KAVACH",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9933), // Saffron
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "AUTHORIZED PERSONNEL ONLY",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ---------- FORM ----------
              _buildTextField("FULL NAME", controller: _nameController, icon: Icons.person),
              const SizedBox(height: 16),
              _buildTextField(
                "OFFICIAL EMAIL",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                "CONTACT NUMBER",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                icon: Icons.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                "SECURE PASSWORD",
                controller: _passwordController,
                obscureText: true,
                icon: Icons.lock,
              ),
              
              const SizedBox(height: 16),

              // DESIGNATION DROPDOWN
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: "DESIGNATION / ROLE",
                  prefixIcon: Icon(Icons.badge),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w600, 
                  color: Color(0xFF003366) // Navy
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(
                      role.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),

              const SizedBox(height: 32),

              // ---------- REGISTER ----------
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  // style handled by Theme
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "INITIATE REGISTRATION",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ---------- LOGIN ----------
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    text: "ALREADY REGISTERED? ",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    children: [
                      TextSpan(
                        text: "ACCESS SYSTEM",
                        style: TextStyle(
                          color: Color(0xFFD32F2F), // Red
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- TEXT FIELD ----------------

  Widget _buildTextField(
    String label, {
    bool obscureText = false,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF003366)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        // Theme handles borders, colors, and styles automatically
      ),
    );
  }
}
