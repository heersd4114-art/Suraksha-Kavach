import 'package:flutter/material.dart';
import 'dashboard_widget.dart';

class EmployeeScreen extends StatelessWidget {
  const EmployeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee View"),
        backgroundColor: Colors.green,
      ),
      body: const DashboardWidget(role: "EMPLOYEE"),
    );
  }
}
