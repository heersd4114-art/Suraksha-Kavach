import 'dart:async';
import 'package:flutter/material.dart';
import '../../shared/api_service.dart';
import '../staff_directory_screen.dart';

class DashboardWidget extends StatefulWidget {
  final String role;
  final bool showControls;

  const DashboardWidget({
    super.key,
    required this.role,
    this.showControls = false,
  });

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  SensorData? _data;
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Poll every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final data = await ApiService.fetchLatestData();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_data == null) {
      return const Center(child: Text("No data available from Device"));
    }

    final isEmergency = _data!.fireDetected || _data!.gasDetected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isEmergency),
          const SizedBox(height: 20),
          _buildSensorCard("Gas Level", _data!.gasLevel.toString(), _data!.gasDetected),
          _buildSensorCard("Fire Level", _data!.fireLevel.toString(), _data!.fireDetected),
          const SizedBox(height: 20),
          _buildStatusCard("Sprinkler System", _data!.sprinklerOn),
          _buildStatusCard("LED Status", !_data!.ledOff), // LED ON means not off
          _buildStaffButton(context),
          const SizedBox(height: 20),
          Text("Last Updated: ${_data!.timestamp}", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isEmergency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEmergency ? Colors.redAccent : Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isEmergency ? Icons.warning : Icons.check_circle,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmergency ? "EMERGENCY ALERT" : "SYSTEM NORMAL",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Designation: ${widget.role}",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, bool isDanger) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(
          isDanger ? Icons.local_fire_department : Icons.air,
          color: isDanger ? Colors.red : Colors.blue,
          size: 30,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDanger ? Colors.red : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, bool isActive) {
    return Card(
      color: isActive ? Colors.blue.shade50 : Colors.grey.shade100,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        trailing: Chip(
          label: Text(isActive ? "ACTIVE" : "INACTIVE"),
          backgroundColor: isActive ? Colors.blue : Colors.grey,
          labelStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStaffButton(BuildContext context) {
    if (widget.role != "OWNER" && widget.role != "DEPT_HEAD") return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.people),
        label: const Text("VIEW STAFF DIRECTORY"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StaffDirectoryScreen()),
          );
        },
      ),
    );
  }
}

