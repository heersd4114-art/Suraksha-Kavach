import 'package:flutter/material.dart';
import 'dashboard_widget.dart';

class DeptHeadScreen extends StatelessWidget {
  const DeptHeadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dept Head Dashboard"),
        backgroundColor: Colors.orange,
      ),
      body: const DashboardWidget(role: "DEPT_HEAD"),
    );
  }
}
