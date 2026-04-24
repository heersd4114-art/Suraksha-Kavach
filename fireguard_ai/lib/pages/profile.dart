import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'logout.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameCtrl = TextEditingController();

  final TextEditingController _phoneCtrl = TextEditingController();

  final TextEditingController _roleCtrl = TextEditingController();

  String _formatDate(Timestamp? time) {
    if (time == null) return "N/A";

    return DateFormat('MMMM yyyy').format(time.toDate());
  }

  // ---------------- Update Profile ----------------

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final role = _roleCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || role.isEmpty) {
      _showMessage("All fields required");
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'phone': phone,
        'role': role,
      });

      if (!mounted) return;

      Navigator.pop(context);

      _showMessage("Profile updated successfully");
    } catch (e) {
      _showMessage("Update failed");
    }
  }

  // ---------------- Edit Dialog ----------------

  void _showEditDialog(String name, String phone, String role) {
    _nameCtrl.text = name;
    _phoneCtrl.text = phone;
    _roleCtrl.text = role;

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile"),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: _nameCtrl,

                decoration: const InputDecoration(labelText: "Name"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,

                decoration: const InputDecoration(labelText: "Phone"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _roleCtrl,

                decoration: const InputDecoration(labelText: "Role"),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: _updateProfile,

              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ---------------- Message ----------------

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0), // Light Grey background
      appBar: AppBar(
        title: const Text(
          "OFFICIAL PERSONNEL ID", 
          style: TextStyle(letterSpacing: 1.2, fontSize: 16)
        ),
        backgroundColor: const Color(0xFF003366), // Navy
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      body: user == null
          ? const Center(child: Text("ACCESS DENIED"))
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Profile Record Not Found"));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = data['name'] ?? "Unknown Personnel";
                final email = data['email'] ?? "N/A";
                final phone = data['phone'] ?? "N/A";
                final role = data['role'] ?? "Staff";
                final createdAt = data['createdAt'] as Timestamp?;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildIdCard(
                          uid: user.uid,
                          name: name,
                          email: email,
                          phone: phone,
                          role: role,
                          joined: _formatDate(createdAt),
                        ),
                        
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _showEditDialog(name, phone, role),
                            icon: const Icon(Icons.edit_note),
                            label: const Text("REQUEST PROFILE UPDATE"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _auth.signOut();
                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LogoutScreen()),
                                (route) => false,
                              );
                            },
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text("END SHIFT / LOGOUT"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD32F2F),
                              side: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ---------------- Official ID Card Layout ----------------

  Widget _buildIdCard({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String role,
    required String joined,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFF9933), // Saffron Header
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Column(
              children: [
                Icon(Icons.shield, color: Colors.white, size: 32),
                SizedBox(height: 4),
                Text(
                  "SURAKSHA KAVACH IDENTITY",
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 14,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Photo
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF003366), width: 3),
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),

          const SizedBox(height: 16),

          // Name & Designation
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD32F2F), // Red for designation
              letterSpacing: 2.0,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(thickness: 1, indent: 40, endIndent: 40),
          const SizedBox(height: 20),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                _buildDetailRow("OFFICIAL EMAIL", email),
                _buildDetailRow("CONTACT NO.", phone),
                _buildDetailRow("SYSTEM ID", uid.substring(0, 8).toUpperCase()),
                _buildDetailRow("ISSUED ON", joined),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Footer Bar code strip (Visual)
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 16),
            child: Image.network(
              "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/QR_code_for_mobile_English_Wikipedia.svg/1200px-QR_code_for_mobile_English_Wikipedia.svg.png", 
              // Placeholder for QR/Barcode visual only for now (or icon)
              errorBuilder: (c,e,s) => const Icon(Icons.qr_code_2, size: 40),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
