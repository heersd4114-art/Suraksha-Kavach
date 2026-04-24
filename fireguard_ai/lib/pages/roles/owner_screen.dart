import 'package:flutter/material.dart';
import 'dashboard_widget.dart';

class OwnerScreen extends StatelessWidget {
  const OwnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Owner Dashboard"),
        backgroundColor: Colors.purple,
      ),
      body: const DashboardWidget(role: "OWNER", showControls: true),
    );
  }
}
