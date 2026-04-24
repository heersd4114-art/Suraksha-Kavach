import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FireHistoryScreen extends StatefulWidget {
  const FireHistoryScreen({super.key});

  @override
  State<FireHistoryScreen> createState() => _FireHistoryScreenState();
}

class _FireHistoryScreenState extends State<FireHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatDate(Timestamp? time) {
    if (time == null) return "N/A";

    return DateFormat('dd MMM yyyy, hh:mm a').format(time.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Fire History")),

      body: user == null
          ? const Center(child: Text("Please login to view history"))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('history')
                  .orderBy('date', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // No history
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyUI();
                }

                final logs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),

                  itemCount: logs.length,

                  itemBuilder: (context, index) {
                    final data = logs[index].data() as Map<String, dynamic>;

                    return _buildHistoryCard(data);
                  },
                );
              },
            ),
    );
  }

  // ---------------- Empty UI ----------------

  Widget _buildEmptyUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: const [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),

            SizedBox(height: 20),

            Text(
              "No Incident History Found",

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Your safety records will appear here once events are detected.",

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- History Card ----------------

  Widget _buildHistoryCard(Map<String, dynamic> log) {
    final title = log['title'] ?? "N/A";
    final location = log['location'] ?? "N/A";
    final status = log['status'] ?? "N/A";
    final severity = log['severity'] ?? "Low";

    final Timestamp? date = log['date'];

    final formattedDate = _formatDate(date);

    // Severity style
    Color color;
    IconData icon;

    switch (severity) {
      case "High":
        color = Colors.red;
        icon = Icons.local_fire_department;
        break;

      case "Medium":
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;

      default:
        color = Colors.green;
        icon = Icons.check_circle_outline;
    }

    return Card(
      elevation: 2,

      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        leading: Container(
          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),

          child: Icon(icon, color: color, size: 28),
        ),

        title: Text(
          title,

          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 5),

            Text("$location • $formattedDate"),

            const SizedBox(height: 5),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),

              child: Text(
                status,

                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              ),
            ),
          ],
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),

        onTap: () {
          // Future: details page
        },
      ),
    );
  }
}
