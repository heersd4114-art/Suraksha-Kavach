import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_screen.dart';

class SocietyDetailsScreen extends StatefulWidget {
  const SocietyDetailsScreen({super.key});

  @override
  State<SocietyDetailsScreen> createState() => _SocietyDetailsScreenState();
}

class _SocietyDetailsScreenState extends State<SocietyDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _chairmanController = TextEditingController();
  final TextEditingController _secretaryController = TextEditingController();

  String? _selectedSociety;

  bool _loading = true;
  bool _saving = false;

  // Society List
  final List<String> _societyList = [
    "Galaxy Heights",
    "Sunshine Apartments",
    "Royal Residency",
    "Green Valley",
    "Blue Sky Towers",
  ];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  // Load saved data
  Future<void> _loadDetails() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data()?['society'];

      if (data != null) {
        _selectedSociety = data['name'];
        _blockController.text = data['block'] ?? "";
        _flatController.text = data['flat'] ?? "";
        _chairmanController.text = data['chairman'] ?? "";
        _secretaryController.text = data['secretary'] ?? "";
      }
    }

    setState(() {
      _loading = false;
    });
  }

  // Save data
  Future<void> _saveDetails() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return;

    if (_selectedSociety == null) {
      _showMsg("Please select society");
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _firestore.collection('users').doc(uid).set({
        'society': {
          'name': _selectedSociety,
          'block': _blockController.text.trim(),
          'flat': _flatController.text.trim(),
          'chairman': _chairmanController.text.trim(),
          'secretary': _secretaryController.text.trim(),
        },
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showMsg("Details saved successfully");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      _showMsg("Failed to save details");
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _blockController.dispose();
    _flatController.dispose();
    _chairmanController.dispose();
    _secretaryController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Society Details")),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),

              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Complete Your Profile",

                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Please enter your residence details below.",

                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 30),

                    // ---------- Society ----------
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _selectedSociety,

                      hint: const Text("Select Society Name"),

                      decoration: InputDecoration(
                        labelText: "Society Name",

                        border: const OutlineInputBorder(),

                        filled: true,
                        fillColor: Colors.grey[100],

                        prefixIcon: const Icon(
                          Icons.apartment,
                          color: Colors.deepOrange,
                        ),
                      ),

                      items: _societyList.map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          _selectedSociety = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // ---------- Block + Flat ----------
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Block No",
                            Icons.domain,
                            _blockController,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: _buildTextField(
                            "Flat Number",
                            Icons.door_front_door,
                            _flatController,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    _buildTextField(
                      "Chairman Name",
                      Icons.person_outline,
                      _chairmanController,
                    ),

                    const SizedBox(height: 15),

                    _buildTextField(
                      "Secretary Name",
                      Icons.badge,
                      _secretaryController,
                    ),

                    const SizedBox(height: 40),

                    // ---------- Save Button ----------
                    SizedBox(
                      width: double.infinity,
                      height: 50,

                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveDetails,

                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,

                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Save Details",

                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------- TextField ----------------

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,

      decoration: InputDecoration(
        labelText: label,

        border: const OutlineInputBorder(),

        filled: true,
        fillColor: Colors.grey[100],

        prefixIcon: Icon(icon, color: Colors.deepOrange),
      ),
    );
  }
}
