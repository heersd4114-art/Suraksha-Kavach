import 'package:flutter/material.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fire Safety & Guidelines")),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          // ================= GENERAL SAFETY =================
          _buildSectionTitle("General Safety Rules"),

          _buildTipCard(
            Icons.warning,
            "Install Smoke Detectors",
            "Ensure smoke detectors are installed and working in every room.",
          ),

          _buildTipCard(
            Icons.electrical_services,
            "Avoid Overloading",
            "Do not overload electrical sockets or extensions.",
          ),

          _buildTipCard(
            Icons.local_fire_department,
            "Keep Flammables Away",
            "Store gas cylinders and chemicals safely.",
          ),

          _buildTipCard(
            Icons.door_back_door,
            "Emergency Exit Plan",
            "Always know your nearest exit routes.",
          ),

          const SizedBox(height: 25),

          // ================= FIRE CLASSES =================
          _buildSectionTitle("Types of Fire & Extinguishing Methods"),

          _buildFireTypeCard(
            "Class A – Solid Fires",
            "Wood, Paper, Cloth",
            "Water, Foam Extinguisher",
            Colors.green,
          ),

          _buildFireTypeCard(
            "Class B – Liquid Fires",
            "Petrol, Oil, Paint",
            "Foam, CO₂ Extinguisher",
            Colors.orange,
          ),

          _buildFireTypeCard(
            "Class C – Gas Fires",
            "LPG, CNG, Natural Gas",
            "CO₂, Dry Powder",
            Colors.blue,
          ),

          _buildFireTypeCard(
            "Class D – Metal Fires",
            "Magnesium, Sodium",
            "Special Dry Powder",
            Colors.purple,
          ),

          _buildFireTypeCard(
            "Class K – Kitchen Fires",
            "Cooking Oil & Fat",
            "Wet Chemical Extinguisher",
            Colors.red,
          ),

          const SizedBox(height: 25),

          // ================= HOW TO USE EXTINGUISHER =================
          _buildSectionTitle("How to Use Fire Extinguisher (PASS Rule)"),

          _buildStepCard(
            "P - Pull",
            "Pull the safety pin from the extinguisher.",
          ),

          _buildStepCard("A - Aim", "Aim at the base of the fire, not flames."),

          _buildStepCard("S - Squeeze", "Squeeze the handle slowly."),

          _buildStepCard("S - Sweep", "Sweep from side to side."),

          const SizedBox(height: 25),

          // ================= EMERGENCY ACTIONS =================
          _buildSectionTitle("Emergency Actions"),

          _buildTipCard(
            Icons.call,
            "Call Emergency Services",
            "Dial fire department immediately.",
          ),

          _buildTipCard(
            Icons.run_circle,
            "Evacuate Quickly",
            "Leave the building calmly and quickly.",
          ),

          _buildTipCard(
            Icons.masks,
            "Cover Nose & Mouth",
            "Use cloth to avoid smoke inhalation.",
          ),

          _buildTipCard(
            Icons.meeting_room,
            "Do Not Use Lifts",
            "Always use stairs in fire emergencies.",
          ),

          const SizedBox(height: 25),

          // ================= HOME SAFETY =================
          _buildSectionTitle("Home & Kitchen Safety"),

          _buildTipCard(
            Icons.kitchen,
            "Never Leave Cooking",
            "Unattended cooking causes most fires.",
          ),

          _buildTipCard(
            Icons.gas_meter,
            "Check Gas Leaks",
            "Close regulator when not in use.",
          ),

          _buildTipCard(
            Icons.water_drop,
            "Never Use Water on Oil Fire",
            "Water spreads kitchen fires.",
          ),

          _buildTipCard(
            Icons.fire_extinguisher,
            "Keep Extinguisher Ready",
            "Install near kitchen & exits.",
          ),

          const SizedBox(height: 30),

          // ================= FOOTER =================
          _buildFooterNote(),
        ],
      ),
    );
  }

  // ================= SECTION TITLE =================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),

      child: Text(
        title,

        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepOrange,
        ),
      ),
    );
  }

  // ================= BASIC TIP CARD =================

  Widget _buildTipCard(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),

              child: Icon(icon, color: Colors.deepOrange),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,

                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= FIRE TYPE CARD =================

  Widget _buildFireTypeCard(
    String title,
    String source,
    String method,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      elevation: 2,

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),

          child: Icon(Icons.local_fire_department, color: color),
        ),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [Text("Source: $source"), Text("Extinguish: $method")],
        ),
      ),
    );
  }

  // ================= STEP CARD =================

  Widget _buildStepCard(String step, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),

      color: Colors.grey[100],

      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),

        title: Text(step, style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Text(desc),
      ),
    );
  }

  // ================= FOOTER =================

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),

      child: Row(
        children: const [
          Icon(Icons.health_and_safety, color: Colors.red),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              "Stay safe! Regularly review fire safety measures and ensure all family members are aware of emergency procedures.",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
