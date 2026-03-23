import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  // --- 🛠️ TEST DATA ADDING FUNCTION ---
  // මේ Function එකෙන් බොරු දත්ත ටිකක් Firebase එකට දානවා, History එක පෙනෙනවාද බලන්න.
  Future<void> _addSampleDonation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('donations').add({
          'userId': user.uid, // ලොග් වී ඇති User ගේ ID එක
          'hospitalName': 'National Hospital Colombo',
          'location': 'Colombo, Sri Lanka',
          'date': Timestamp.now(), // දැන් වෙලාව
          'amount': '450ml',
          'status': 'Completed',
          'certificateUrl': '', // සහතිකයක් තිබේ නම් එහි ලින්ක් එක
        });
        debugPrint("Test data added successfully!");
      } catch (e) {
        debugPrint("Error adding data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Donations", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      // 👇 මේ Button එක ඔබලා Data Add කරගන්න (පරීක්ෂා කිරීමට පමණයි)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSampleDonation,
        label: const Text("Add Test Record"),
        icon: const Icon(Icons.add_task_rounded),
        backgroundColor: const Color(0xFFC62828),
      ),

      body: StreamBuilder<QuerySnapshot>(
        // Firestore එකෙන් දත්ත ලබා ගැනීම
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('userId', isEqualTo: user?.uid) // User ට අදාළ දත්ත පමණක් පෙරීම
            .orderBy('date', descending: true)     // අලුත්ම දින උඩට ගැනීම
            .snapshots(),
        builder: (context, snapshot) {

          // 1. දෝෂයක් ආවොත් (ගොඩක් වෙලාවට Index Error එක)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error: ${snapshot.error}\n\n(Check your Debug Console for a Link to create an Index!)",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // 2. දත්ත Load වෙමින් පවතී නම්
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          // 3. දත්ත කිසිවක් නැත්නම්
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // 4. දත්ත තිබේ නම් List එක පෙන්වීම
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildHistoryCard(data);
            },
          );
        },
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: Icon(Icons.history_edu_rounded, size: 60, color: Colors.red[200]),
          ),
          const SizedBox(height: 20),
          const Text("No Donations Yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          const Text("Use the button below to add a test record.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    // දිනය Format කිරීම
    Timestamp t = data['date'] ?? Timestamp.now();
    DateTime date = t.toDate();
    String day = DateFormat('dd').format(date);
    String month = DateFormat('MMM').format(date);
    String year = DateFormat('yyyy').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Date Badge
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFC62828).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFC62828))),
                  Text(month, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFC62828))),
                ],
              ),
            ),
            const SizedBox(width: 15),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['hospitalName'] ?? "Unknown Hospital",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(data['location'] ?? "Sri Lanka", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                    child: Text("Successfully Donated", style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

            // Blood Drop Icon
            const Icon(Icons.bloodtype_rounded, color: Colors.red, size: 28),
          ],
        ),
      ),
    );
  }
}