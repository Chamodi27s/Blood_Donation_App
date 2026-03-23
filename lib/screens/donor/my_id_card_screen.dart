import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class MyIdCardScreen extends StatefulWidget {
  const MyIdCardScreen({super.key});

  @override
  State<MyIdCardScreen> createState() => _MyIdCardScreenState();
}

class _MyIdCardScreenState extends State<MyIdCardScreen> {
  final ScreenshotController screenshotController = ScreenshotController();

  // --- Card එක Share කිරීමේ Logic එක ---
  void _shareCard() async {
    try {
      final Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/donor_card.png').create();
        await imagePath.writeAsBytes(imageBytes);
        await Share.shareXFiles([XFile(imagePath.path)], text: 'My Digital Donor Pass from Blood Link!');
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  String _getInitial(String name) {
    if (name.isEmpty) return "D";
    return name.trim()[0].toUpperCase();
  }

  // --- View Details Bottom Sheet (Fixed Overflow) ---
  void _showUserDetailSheet(BuildContext context, Map<String, dynamic> data, String email) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // උස පාලනය කිරීමට
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25.0),
          // Screen එකෙන් 60% කට වඩා වැඩි නොවන ලෙස සකසනවා
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle තීරුව
              Container(
                width: 40, height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),

              // Scroll කරලා බැලිය හැකි විස්තර කොටස
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Donor Profile Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildDetailItem(Icons.person_rounded, "Full Name", data['name'] ?? 'N/A'),
                      _buildDetailItem(Icons.email_rounded, "Email Address", email),
                      _buildDetailItem(Icons.phone_rounded, "Phone Number", data['phone'] ?? 'Not provided'),
                      _buildDetailItem(Icons.bloodtype_rounded, "Blood Group", data['bloodGroup'] ?? 'N/A'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Close Button (ස්ථාවරව යටින් පවතී)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFC62828).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFFC62828), size: 22),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Digital Pass", style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFFC62828)),
            onPressed: _shareCard,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackgroundDecoration(),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.red));

              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String name = userData['name'] ?? "Donor Name";
              String bloodGroup = userData['bloodGroup'] ?? "N/A";

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  children: [
                    _buildDigitalCard(name, bloodGroup, user.uid),
                    const SizedBox(height: 35),
                    _buildSectionHeader("Card Status"),
                    _buildStatusCard(userData, user.email ?? "N/A"),
                    const SizedBox(height: 25),
                    _buildSectionHeader("Quick Information"),
                    _buildInfoTile(Icons.verified_rounded, "Official Member", "Verified Donor Account", Colors.blue),
                    _buildInfoTile(Icons.qr_code_2_rounded, "Digital ID", "Unique QR Access Enabled", Colors.purple),
                    _buildInfoTile(Icons.health_and_safety_rounded, "Guidelines", "Valid for all registered camps", Colors.green),
                    const SizedBox(height: 30),
                    _buildMainButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _buildDigitalCard(String name, String bloodGroup, String uid) {
    return Screenshot(
      controller: screenshotController,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: const Color(0xFFC62828).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 12)),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 1.586,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFC62828), Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20, top: -20,
                  child: Icon(Icons.bloodtype_rounded, size: 200, color: Colors.white.withOpacity(0.07)),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(),
                      const Spacer(),
                      _buildCardFooter(name, bloodGroup, uid),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("BLOOD LINK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2)),
            Text("DIGITAL DONOR PASS", style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  Widget _buildCardFooter(String name, String bloodGroup, String uid) {
    return Row(
      children: [
        Container(
          width: 65, height: 65,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(_getInitial(name), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text("BLOOD GROUP: $bloodGroup", style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: QrImageView(data: uid, version: QrVersions.auto, size: 55.0, padding: const EdgeInsets.all(2)),
        ),
      ],
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> data, String email) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.check_circle, color: Colors.green)),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Account Verified", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text("Active Donor", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _showUserDetailSheet(context, data, email),
            child: const Text("View Details"),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Stack(
      children: [
        Positioned(top: 100, right: -60, child: CircleAvatar(radius: 100, backgroundColor: Colors.red.withOpacity(0.03))),
        Positioned(bottom: 50, left: -60, child: CircleAvatar(radius: 130, backgroundColor: Colors.red.withOpacity(0.03))),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700], letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: _shareCard,
        icon: const Icon(Icons.share_rounded, color: Colors.white),
        label: const Text("SHARE DIGITAL PASS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
    );
  }
}