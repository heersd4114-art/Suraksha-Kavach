import 'package:flutter/material.dart';
import 'pages/roles/owner_screen.dart';
import 'pages/roles/dept_head_screen.dart';
import 'pages/roles/manager_screen.dart';
import 'pages/roles/employee_screen.dart';

// 1. This is your existing HomeScreen with a new Button added
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend gradient behind AppBar
      appBar: AppBar(
        title: const Text("Suraksha Kavach"),
        backgroundColor: Colors.transparent, // Transparent for gradient
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF003366), Color(0xFF001A33)], // Navy Gradient
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              ),
              
              const SizedBox(height: 30),
              
              // Dashboard Text with "Tag" style to match Splash
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Text(
                  "Dashboard",
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w600,
                    color: Colors.white
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Role Selection for Demo
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildRoleButton(context, "Owner", Colors.purple, const OwnerScreen()),
                  _buildRoleButton(context, "Dept Head", Colors.orange, const DeptHeadScreen()),
                  _buildRoleButton(context, "Manager", Colors.blue, const ManagerScreen()),
                  _buildRoleButton(context, "Employee", Colors.green, const EmployeeScreen()),
                ],
              ),
              
              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9933), // Saffron Button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFFFF9933).withValues(alpha: 0.5),
                ),
                child: const Text(
                  "Regular Login",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String label, Color color, Widget page) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }
}

// 2. This is the simple Login Screen destination
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: const Center(child: Text("Login Page Content Goes Here")),
    );
  }
}
