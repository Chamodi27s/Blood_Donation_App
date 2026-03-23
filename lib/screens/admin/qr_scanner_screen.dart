import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // v5.x compatible
import 'package:cloud_firestore/cloud_firestore.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // Mobile Scanner Controller
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isScanCompleted = false; // එක පාරක් ස්කෑන් වුනාම නවත්තන්න
  bool _isLoading = false;

  // --- 1. ලේ දීම තහවුරු කර දත්ත ඇතුළත් කිරීම (Save to Firebase) ---
  Future<void> _recordDonation(String donorId, String donorName) async {
    try {
      await FirebaseFirestore.instance.collection('donations').add({
        'userId': donorId,
        'hospitalName': 'National Hospital Colombo',
        'location': 'Colombo',
        'date': Timestamp.now(),
        'amount': '450ml',
        'status': 'Completed',
        'donorName': donorName,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Donation Recorded Successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context); // Scanner එකෙන් ඉවත් වීම
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- 2. QR එකෙන් Donor ව සොයා ගැනීම (Verify) ---
  void _verifyDonor(String donorId) async {
    setState(() => _isLoading = true);

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(donorId).get();

      if (!mounted) return;

      if (userDoc.exists) {
        String donorName = userDoc['name'] ?? 'Unknown Donor';
        String bloodGroup = userDoc['bloodGroup'] ?? 'N/A';

        // Admin ට තහවුරු කරන්න Dialog එකක්
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green),
                SizedBox(width: 10),
                Text("Verify Donor"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Name:", donorName),
                _buildInfoRow("Blood Group:", bloodGroup),
                const SizedBox(height: 10),
                const Divider(),
                const Text("Mark this donation as completed?", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _isScanCompleted = false; // ආපහු ස්කෑන් කරන්න දෙනවා
                    _isLoading = false;
                  });
                },
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _recordDonation(donorId, donorName); // දත්ත Save කරනවා
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                child: const Text("CONFIRM & SAVE", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        );
      } else {
        _showError("Invalid Donor QR! User not found.");
      }
    } catch (e) {
      _showError("Error finding user. Invalid QR.");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    setState(() {
      _isScanCompleted = false;
      _isLoading = false;
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Donor Pass"),
        actions: [
          // Flashlight Button (Updated for Mobile Scanner v5+)
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, state, child) {
              // අලුත් ක්‍රමය: state.torchState හරහා පරීක්ෂා කිරීම
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off, color: isTorchOn ? Colors.yellow : Colors.grey),
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!_isScanCompleted && !_isLoading) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    setState(() => _isScanCompleted = true);
                    _verifyDonor(barcode.rawValue!);
                  }
                }
              }
            },
          ),

          // --- Custom Overlay ---
          _buildScannerOverlay(),

          // --- Loading Indicator ---
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 4),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const Positioned(
          bottom: 100, left: 0, right: 0,
          child: Text(
            "Align QR Code within the frame",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 10, color: Colors.black)]
            ),
          ),
        )
      ],
    );
  }
}