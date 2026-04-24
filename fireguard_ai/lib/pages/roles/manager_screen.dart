import 'package:flutter/material.dart';
import 'dashboard_widget.dart';

class ManagerScreen extends StatelessWidget {
  const ManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Dashboard"),
        backgroundColor: Colors.blue,
      ),
      body: const DashboardWidget(role: "MANAGER"),
    );
  }
}
