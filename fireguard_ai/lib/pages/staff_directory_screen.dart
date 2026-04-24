import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffDirectoryScreen extends StatelessWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("STAFF DIRECTORY"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No staff members found."));
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown Name';
              final email = data['email'] ?? 'No Email';
              final role = (data['role'] ?? 'Staff').toString().toUpperCase();
              final designation = data['designation'] ?? role;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(designation, style: const TextStyle(color: Colors.black87)),
                    Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                trailing: Chip(
                  label: Text(role, style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: _getRoleColor(role),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'OWNER': return const Color(0xFF003366);
      case 'MANAGER': return Colors.teal;
      case 'DEPT_HEAD': return Colors.orange;
      case 'FIRE_STATION': return Colors.red;
      default: return Colors.blueGrey;
    }
  }
}
