import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyQrCodeScreen extends StatelessWidget {
  const MyQrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String userEmail = FirebaseAuth.instance.currentUser!.email ?? "Donor";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // ඉතාම ලා අළු පසුබිම
      appBar: AppBar(
        title: const Text("Donor QR Pass", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // --- Background Decorations ---
          Positioned(
            top: -50, right: -50,
            child: CircleAvatar(radius: 100, backgroundColor: Colors.red.withOpacity(0.05)),
          ),
          Positioned(
            bottom: -30, left: -40,
            child: CircleAvatar(radius: 80, backgroundColor: Colors.red.withOpacity(0.05)),
          ),

          // --- Main Content ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon & Instruction
                  const Icon(Icons.qr_code_scanner_rounded, size: 50, color: Color(0xFFC62828)),
                  const SizedBox(height: 15),
                  const Text(
                    "Scan for Verification",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Show this code to the hospital administrator\nto record your donation.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                  ),

                  const SizedBox(height: 40),

                  // --- QR Card ---
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // Scanner Frame effect
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red.withOpacity(0.1), width: 2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: QrImageView(
                            data: userId,
                            version: QrVersions.auto,
                            size: 200.0,
                            foregroundColor: const Color(0xFF2D3436), // පිරිසිදු තද අළු පාට
                          ),
                        ),
                        const SizedBox(height: 20),

                        // User Info Badge inside card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alternate_email_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                userEmail,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- Security Footer ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded, size: 18, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        "SECURE DIGITAL PASS",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}