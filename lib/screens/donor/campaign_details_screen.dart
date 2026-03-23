import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CampaignDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final DateTime date;
  final String campaignId;

  const CampaignDetailsScreen({
    super.key,
    required this.data,
    required this.date,
    required this.campaignId,
  });

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  final List<String> allTimeSlots = [
    "09:00 AM",
    "09:30 AM",
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "02:00 PM",
    "02:30 PM",
  ];

  final Color primaryBlue = const Color(0xFF3949AB);
  final Color softBg = const Color(0xFFF6F8FC);

  String? selectedSlot;
  bool isBooking = false;

  Future<void> _bookAppointment() async {
    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a time slot!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isBooking = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final existingBooking = await FirebaseFirestore.instance
          .collection('appointments')
          .where('campaignId', isEqualTo: widget.campaignId)
          .where('donorId', isEqualTo: user.uid)
          .where('status', whereIn: ['Pending', 'Approved'])
          .get();

      if (existingBooking.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You already have an active booking for this campaign."),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => isBooking = false);
        return;
      }

      final slotCheck = await FirebaseFirestore.instance
          .collection('appointments')
          .where('campaignId', isEqualTo: widget.campaignId)
          .where('timeSlot', isEqualTo: selectedSlot)
          .where('status', whereIn: ['Pending', 'Approved'])
          .get();

      if (slotCheck.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This time slot has just been booked. Please select another one.",
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => isBooking = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;
      final donorName = userData?['name']?.toString() ?? "Unknown Donor";

      await FirebaseFirestore.instance.collection('appointments').add({
        'campaignId': widget.campaignId,
        'campaignName': widget.data['name'] ?? 'Campaign',
        'donorId': user.uid,
        'donorName': donorName,
        'date': Timestamp.fromDate(widget.date),
        'timeSlot': selectedSlot,
        'status': 'Pending',
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 52,
              ),
              SizedBox(height: 10),
              Text(
                "Confirmed!",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Text(
            "Appointment for ${widget.data['name']} at $selectedSlot has been placed successfully.",
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isBooking = false);
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -10,
            child: Icon(
              Icons.volunteer_activism_rounded,
              size: 170,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          const Center(
            child: Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 78,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryBlue, size: 28),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: primaryBlue,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.data['name'] ?? "Campaign Details",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: _buildHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildInfoBox(
                        Icons.calendar_month_rounded,
                        DateFormat('MMM dd, yyyy').format(widget.date),
                      ),
                      const SizedBox(width: 14),
                      _buildInfoBox(
                        Icons.location_on_rounded,
                        widget.data['location'] ?? "Unknown",
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Select Time Slot"),
                  const SizedBox(height: 14),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .where('campaignId', isEqualTo: widget.campaignId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      final bookedSlots = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status =
                            (data['status'] ?? '').toString().toLowerCase();
                        return status == 'pending' || status == 'approved';
                      }).map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['timeSlot'] ?? '').toString();
                      }).toList();

                      final availableSlots = allTimeSlots
                          .where((slot) => !bookedSlots.contains(slot))
                          .toList();

                      if (availableSlots.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            "Fully Booked!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: availableSlots.map((time) {
                          final isSelected = selectedSlot == time;
                          return ChoiceChip(
                            label: Text(time),
                            selected: isSelected,
                            selectedColor: primaryBlue,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                color: isSelected
                                    ? primaryBlue
                                    : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                selectedSlot = selected ? time : null;
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isBooking ? null : _bookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        disabledBackgroundColor: primaryBlue.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: isBooking
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "BOOK APPOINTMENT",
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}