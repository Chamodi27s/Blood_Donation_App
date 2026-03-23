import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  final Color primaryRed = const Color(0xFFD32F2F);
  final Color softBg = const Color(0xFFF5F7FA);

  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Completed',
    'Cancelled',
  ];

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    String newStatus,
    String donorId,
    String campaignName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({'status': newStatus});

      String message = switch (newStatus.toLowerCase()) {
        'approved' =>
          "✅ Your appointment for '$campaignName' has been approved. Please be there on time.",
        'rejected' =>
          "❌ Your appointment for '$campaignName' was rejected. Please contact us for more info.",
        'completed' =>
          "🎉 Your appointment for '$campaignName' has been marked as completed.",
        'cancelled' =>
          "⚠️ Your appointment for '$campaignName' has been cancelled.",
        _ => "Your appointment for '$campaignName' was updated.",
      };

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': donorId,
        'title': "Appointment $newStatus",
        'body': message,
        'createdAt': Timestamp.now(),
        'isRead': false,
        'type': 'booking_update',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booking $newStatus successfully"),
          backgroundColor: _statusColor(newStatus),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating status: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    if (_selectedFilter == 'All') return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? 'Pending').toString().trim().toLowerCase();
      return status == _selectedFilter.toLowerCase();
    }).toList();
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedFilter = filter);
              },
              selectedColor: primaryRed,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: selected ? primaryRed : Colors.grey.withOpacity(0.14),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    // අගට ඇති හිස්තැන් මකා දැමීමට .trim() භාවිතා කර ඇත
    final String status = (data['status'] ?? 'Pending').toString().trim().toLowerCase();
    final String donorId = (data['donorId'] ?? '').toString();
    final String campaignName = (data['campaignName'] ?? 'Campaign').toString();

    if (status == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _updateStatus(
              context,
              docId,
              'Rejected',
              donorId,
              campaignName,
            ),
            child: const Text(
              "Reject",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _updateStatus(
              context,
              docId,
              'Approved',
              donorId,
              campaignName,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              "Approve",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    if (status == 'approved') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _updateStatus(
              context,
              docId,
              'Cancelled',
              donorId,
              campaignName,
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _updateStatus(
              context,
              docId,
              'Completed',
              donorId,
              campaignName,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              "Complete",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 15),
            Text(
              "No bookings available",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: const Text(
          "Campaign Bookings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryRed,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD32F2F),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aCreated = aData['createdAt'];
            final bCreated = bData['createdAt'];

            if (aCreated is Timestamp && bCreated is Timestamp) {
              return bCreated.toDate().compareTo(aCreated.toDate());
            }
            return 0;
          });

          final filteredDocs = _filterDocs(docs);

          final pendingCount = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? 'Pending').toString().trim().toLowerCase() == 'pending';
          }).length;

          final approvedCount = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '').toString().trim().toLowerCase() == 'approved';
          }).length;

          final completedCount = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '').toString().trim().toLowerCase() == 'completed';
          }).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildFilterChips(),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStatCard("Pending", "$pendingCount", Colors.orange),
                    const SizedBox(width: 10),
                    _buildStatCard("Approved", "$approvedCount", Colors.green),
                    const SizedBox(width: 10),
                    _buildStatCard("Completed", "$completedCount", Colors.blue),
                  ],
                ),
              ),
              Expanded(
                child: filteredDocs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          // මෙතන try-catch එකක් දැම්මා මුළු screen එකම crash වෙන එක නවත්වන්න
                          try {
                            final doc = filteredDocs[index];
                            final data = doc.data() as Map<String, dynamic>? ?? {};
                            
                            final String rawStatus = (data['status'] ?? 'Pending').toString();
                            final String status = rawStatus.trim(); // Trimmed Status
                            
                            DateTime date = DateTime.now();
                            if (data['date'] != null) {
                              if (data['date'] is Timestamp) {
                                date = (data['date'] as Timestamp).toDate();
                              } else {
                                date = DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
                              }
                            }

                            final Color statusColor = _statusColor(status);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                                border: Border(
                                  left: BorderSide(color: statusColor, width: 5),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            (data['campaignName'] ?? 'Campaign').toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildInfoRow(
                                      Icons.person,
                                      (data['donorName'] ?? 'Unknown Donor').toString(),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildInfoRow(
                                      Icons.access_time_filled,
                                      "${DateFormat('MMM dd, yyyy').format(date)} @ ${(data['timeSlot'] ?? '').toString()}",
                                    ),
                                    const SizedBox(height: 6),
                                    _buildInfoRow(
                                      Icons.confirmation_number_outlined,
                                      "Campaign ID: ${(data['campaignId'] ?? '').toString()}",
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    _buildActionButtons(context, doc.id, data),
                                  ],
                                ),
                              ),
                            );
                          } catch (e) {
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.red.shade200)
                              ),
                              child: Text(
                                "Error loading booking data: $e",
                                style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                              ),
                            );
                          }
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}