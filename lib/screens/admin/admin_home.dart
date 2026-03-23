import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'create_request_screen.dart';
import 'manage_donors_screen.dart';
import 'manage_campaigns_screen.dart';
import 'qr_scanner_screen.dart';
import 'admin_appointments_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final Color primaryRed = const Color(0xFFD32F2F);
  final Color darkRed = const Color(0xFFB71C1C);
  final Color softBg = const Color(0xFFF6F8FB);
  final Color cardColor = Colors.white;

  String _searchQuery = '';
  String _selectedUrgencyFilter = 'All';
  String _selectedBloodFilter = 'All';

  final List<String> urgencyFilters = ['All', 'Critical', 'Normal'];
  final List<String> bloodFilters = [
    'All',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  Future<void> _refreshDashboard() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() {});
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Map<String, dynamic> _docData(QueryDocumentSnapshot doc) {
    return doc.data() as Map<String, dynamic>;
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = _docData(doc);

      final patientName = (data['patientName'] ?? '').toString().toLowerCase();
      final hospitalName = (data['hospitalName'] ?? '').toString().toLowerCase();
      final bloodGroup = (data['bloodGroup'] ?? '').toString().toUpperCase();
      final urgency = (data['urgency'] ?? '').toString().toLowerCase();
      final search = _searchQuery.toLowerCase();

      final matchesSearch = search.isEmpty ||
          patientName.contains(search) ||
          hospitalName.contains(search) ||
          bloodGroup.toLowerCase().contains(search);

      bool matchesUrgency = true;
      if (_selectedUrgencyFilter == 'Critical') {
        matchesUrgency = urgency == 'critical';
      } else if (_selectedUrgencyFilter == 'Normal') {
        matchesUrgency = urgency != 'critical';
      }

      bool matchesBlood = true;
      if (_selectedBloodFilter != 'All') {
        matchesBlood = bloodGroup == _selectedBloodFilter;
      }

      return matchesSearch && matchesUrgency && matchesBlood;
    }).toList();
  }

  Future<void> _updateRequestStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(docId).update({
        'status': newStatus,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request marked as $newStatus"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to update status"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF1E88E5);
      case 'in progress':
        return const Color(0xFFFB8C00);
      case 'fulfilled':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  List<PieChartSectionData> _getSections(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> counts = {};

    for (var doc in docs) {
      final data = _docData(doc);
      final bg = (data['bloodGroup'] ?? 'Other').toString();
      counts[bg] = (counts[bg] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade300,
          radius: 24,
          showTitle: false,
        ),
      ];
    }

    final List<Color> colors = [
      const Color(0xFFE53935),
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFFB8C00),
      const Color(0xFF8E24AA),
      const Color(0xFF00897B),
      const Color(0xFF6D4C41),
    ];

    int i = 0;
    return counts.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: color,
        radius: 24,
        showTitle: false,
      );
    }).toList();
  }

  Widget _buildChartLegend(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> counts = {};

    for (var doc in docs) {
      final data = _docData(doc);
      final bg = (data['bloodGroup'] ?? 'Other').toString();
      counts[bg] = (counts[bg] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return Text(
        "No request data available",
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final List<Color> colors = [
      const Color(0xFFE53935),
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFFB8C00),
      const Color(0xFF8E24AA),
      const Color(0xFF00897B),
      const Color(0xFF6D4C41),
    ];

    int i = 0;
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: counts.entries.map((entry) {
        final color = colors[i % colors.length];
        i++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "${entry.key} (${entry.value})",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Delete Request?"),
        content: const Text("This request will be removed permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('requests')
                  .doc(docId)
                  .delete();

              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showRequestDetails({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final patientName = (data['patientName'] ?? 'Unknown').toString();
    final hospitalName = (data['hospitalName'] ?? 'Hospital').toString();
    final bloodGroup = (data['bloodGroup'] ?? '?').toString();
    final urgency = (data['urgency'] ?? 'Normal').toString();
    final requestStatus = (data['status'] ?? 'Pending').toString();
    final comingCount = (data['comingDonors'] as List? ?? []).length;
    final note =
        (data['note'] ?? data['reason'] ?? 'No additional notes').toString();

    final statusColor = _statusColor(requestStatus);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: urgency.toLowerCase() == 'critical'
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          bloodGroup,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: urgency.toLowerCase() == 'critical'
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hospitalName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              requestStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow("Blood Group", bloodGroup),
                _detailRow("Urgency", urgency),
                _detailRow("Status", requestStatus),
                _detailRow("Coming Donors", "$comingCount"),
                _detailRow("Note", note),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text("Close"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(docId);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text("Delete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required Widget child, int delay = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 450 + delay),
      tween: Tween(begin: 0.94, end: 1),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
    );
  }

  DateTime? _extractAppointmentDate(Map<String, dynamic> data) {
    final raw = data['appointmentDate'] ?? data['date'];
    if (raw is Timestamp) return raw.toDate();
    return null;
  }

  Widget _buildTopHeader(int total, int critical, int donorCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkRed, primaryRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Admin Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Monitor blood requests and manage operations",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _logout,
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderMiniInfo("Total", "$total"),
                _dividerWhite(),
                _buildHeaderMiniInfo("Critical", "$critical"),
                _dividerWhite(),
                _buildHeaderMiniInfo("Donors", "$donorCount"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: _cardDecoration(),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        decoration: InputDecoration(
          hintText: "Search by patient, hospital, blood group...",
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => setState(() => _searchQuery = ''),
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: primaryRed.withOpacity(0.25)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: urgencyFilters.map((filter) {
          final selected = _selectedUrgencyFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedUrgencyFilter = filter;
                });
              },
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              selectedColor: primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: selected ? primaryRed : Colors.grey.withOpacity(0.15),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBloodFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: bloodFilters.map((filter) {
          final selected = _selectedBloodFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedBloodFilter = filter;
                });
              },
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1565C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF1565C0)
                      : Colors.grey.withOpacity(0.15),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeaderMiniInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _dividerWhite() {
    return Container(
      width: 1,
      height: 34,
      color: Colors.white.withOpacity(0.25),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Colors.grey[700],
        letterSpacing: 1.1,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    int delay = 0,
  }) {
    return Expanded(
      child: _buildAnimatedCard(
        delay: delay,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniOverviewTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    IconData icon,
    Color bg,
    Color iconColor,
    Widget screen,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Ink(
          decoration: _cardDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _logout,
        child: Ink(
          decoration: _cardDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: primaryRed,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Logout",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildRequestCard({
    required String docId,
    required Map<String, dynamic> data,
    required String patientName,
    required String hospitalName,
    required String bloodGroup,
    required String urgency,
    required int comingCount,
    required bool isCritical,
  }) {
    final requestStatus = (data['status'] ?? 'Pending').toString();
    final statusColor = _statusColor(requestStatus);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _showRequestDetails(docId: docId, data: data);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCritical
                  ? Colors.red.withOpacity(0.20)
                  : statusColor.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: isCritical
                    ? Colors.red.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isCritical
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    bloodGroup,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isCritical
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF1565C0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hospitalName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildBadge(
                          text: urgency.toString().isEmpty ? "Normal" : urgency,
                          bg: isCritical
                              ? Colors.red.withOpacity(0.08)
                              : Colors.grey.withOpacity(0.08),
                          fg: isCritical ? Colors.red : Colors.grey[700]!,
                        ),
                        _buildBadge(
                          text: requestStatus,
                          bg: statusColor.withOpacity(0.10),
                          fg: statusColor,
                        ),
                        if (comingCount > 0)
                          _buildBadge(
                            text: "$comingCount donor(s) coming",
                            bg: Colors.green.withOpacity(0.10),
                            fg: Colors.green[700]!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  if (value == 'view') {
                    _showRequestDetails(docId: docId, data: data);
                  } else if (value == 'pending') {
                    _updateRequestStatus(docId, 'Pending');
                  } else if (value == 'approved') {
                    _updateRequestStatus(docId, 'Approved');
                  } else if (value == 'progress') {
                    _updateRequestStatus(docId, 'In Progress');
                  } else if (value == 'fulfilled') {
                    _updateRequestStatus(docId, 'Fulfilled');
                  } else if (value == 'cancelled') {
                    _updateRequestStatus(docId, 'Cancelled');
                  } else if (value == 'delete') {
                    _confirmDelete(docId);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'view', child: Text("View Details")),
                  PopupMenuItem(value: 'pending', child: Text("Mark Pending")),
                  PopupMenuItem(value: 'approved', child: Text("Mark Approved")),
                  PopupMenuItem(value: 'progress', child: Text("Mark In Progress")),
                  PopupMenuItem(value: 'fulfilled', child: Text("Mark Fulfilled")),
                  PopupMenuItem(value: 'cancelled', child: Text("Mark Cancelled")),
                  PopupMenuItem(value: 'delete', child: Text("Delete")),
                ],
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner(Map<String, dynamic> data) {
    final patientName = (data['patientName'] ?? 'Unknown').toString();
    final hospitalName = (data['hospitalName'] ?? 'Hospital').toString();
    final bloodGroup = (data['bloodGroup'] ?? '?').toString();
    final status = (data['status'] ?? 'Pending').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEBEE), Color(0xFFFFF5F5)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.red.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Emergency Request Alert",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$patientName • $bloodGroup",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hospitalName,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Status: $status",
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryRed.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 32,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "No Requests Found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Try changing search or filter options.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      body: RefreshIndicator(
        color: primaryRed,
        onRefresh: _refreshDashboard,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: primaryRed),
              );
            }

            if (requestSnapshot.hasError) {
              return Center(
                child: Text(
                  "Something went wrong",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            final docs = requestSnapshot.data?.docs ?? [];
            final filteredDocs = _filterDocs(docs);

            final total = docs.length;
            final critical = docs.where((d) {
              final data = _docData(d);
              return (data['urgency'] ?? '').toString().toLowerCase() ==
                  'critical';
            }).length;

            final latestCritical = docs.cast<QueryDocumentSnapshot?>().firstWhere(
                  (d) =>
                      d != null &&
                      (_docData(d)['urgency'] ?? '')
                              .toString()
                              .toLowerCase() ==
                          'critical',
                  orElse: () => null,
                );

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'donor')
                  .snapshots(),
              builder: (context, donorSnapshot) {
                final donorCount = donorSnapshot.data?.docs.length ?? 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .snapshots(),
                  builder: (context, appointmentSnapshot) {
                    final appointmentDocs = appointmentSnapshot.data?.docs ?? [];
                    final today = DateTime.now();

                    final todayAppointments = appointmentDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = _extractAppointmentDate(data);
                      if (date == null) return false;
                      return date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day;
                    }).length;

                    final pendingAppointments = appointmentDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['status'] ?? '')
                              .toString()
                              .toLowerCase() ==
                          'pending';
                    }).length;

                    final completedAppointments = appointmentDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status =
                          (data['status'] ?? '').toString().toLowerCase();
                      return status == 'completed' || status == 'fulfilled';
                    }).length;

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildTopHeader(total, critical, donorCount),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAnimatedCard(
                                  delay: 50,
                                  child: _buildSearchBar(),
                                ),
                                const SizedBox(height: 14),
                                _buildAnimatedCard(
                                  delay: 80,
                                  child: _buildUrgencyFilterChips(),
                                ),
                                const SizedBox(height: 10),
                                _buildAnimatedCard(
                                  delay: 110,
                                  child: _buildBloodFilterChips(),
                                ),
                                const SizedBox(height: 20),
                                if (latestCritical != null)
                                  _buildAnimatedCard(
                                    delay: 140,
                                    child: _buildEmergencyBanner(
                                      _docData(latestCritical),
                                    ),
                                  ),
                                if (latestCritical != null)
                                  const SizedBox(height: 20),
                                Row(
                                  children: [
                                    _buildStatCard(
                                      "Requests",
                                      "$total",
                                      Icons.assignment_rounded,
                                      const Color(0xFF1565C0),
                                      delay: 150,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildStatCard(
                                      "Critical",
                                      "$critical",
                                      Icons.warning_amber_rounded,
                                      const Color(0xFFD32F2F),
                                      delay: 220,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildStatCard(
                                      "Donors",
                                      "$donorCount",
                                      Icons.groups_rounded,
                                      const Color(0xFFEF6C00),
                                      delay: 290,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _sectionTitle("Quick Overview"),
                                const SizedBox(height: 12),
                                _buildAnimatedCard(
                                  delay: 180,
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: _cardDecoration(),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildMiniOverviewTile(
                                                "Today Appointments",
                                                "$todayAppointments",
                                                Icons.today_rounded,
                                                const Color(0xFF1565C0),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildMiniOverviewTile(
                                                "Pending",
                                                "$pendingAppointments",
                                                Icons.access_time_rounded,
                                                const Color(0xFFFB8C00),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildMiniOverviewTile(
                                                "Completed",
                                                "$completedAppointments",
                                                Icons.check_circle_rounded,
                                                const Color(0xFF2E7D32),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildMiniOverviewTile(
                                                "Showing",
                                                "${filteredDocs.length}",
                                                Icons.filter_alt_rounded,
                                                primaryRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _sectionTitle("Blood Demand Analytics"),
                                const SizedBox(height: 12),
                                _buildAnimatedCard(
                                  delay: 210,
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: _cardDecoration(),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          height: 130,
                                          width: 130,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              PieChart(
                                                PieChartData(
                                                  sections: _getSections(filteredDocs),
                                                  centerSpaceRadius: 38,
                                                  sectionsSpace: 3,
                                                ),
                                              ),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.bloodtype_rounded,
                                                    color: primaryRed,
                                                    size: 24,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "${filteredDocs.length}",
                                                    style: TextStyle(
                                                      color: Colors.grey[800],
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: _buildChartLegend(filteredDocs),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _sectionTitle("Quick Actions"),
                                const SizedBox(height: 12),
                                _buildAnimatedCard(
                                  delay: 240,
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 1.22,
                                    children: [
                                      _buildActionBtn(
                                        "New Request",
                                        Icons.add_circle_outline_rounded,
                                        const Color(0xFFFFEBEE),
                                        const Color(0xFFD32F2F),
                                        const CreateRequestScreen(),
                                      ),
                                      _buildActionBtn(
                                        "Manage Donors",
                                        Icons.people_alt_outlined,
                                        const Color(0xFFFFF3E0),
                                        const Color(0xFFEF6C00),
                                        const ManageDonorsScreen(),
                                      ),
                                      _buildActionBtn(
                                        "Campaigns",
                                        Icons.campaign_rounded,
                                        const Color(0xFFF3E5F5),
                                        const Color(0xFF8E24AA),
                                        const ManageCampaignsScreen(),
                                      ),
                                      _buildActionBtn(
                                        "QR Scanner",
                                        Icons.qr_code_scanner_rounded,
                                        const Color(0xFFE3F2FD),
                                        const Color(0xFF1565C0),
                                        const QrScannerScreen(),
                                      ),
                                      _buildActionBtn(
                                        "Bookings",
                                        Icons.calendar_month_rounded,
                                        const Color(0xFFE8F5E9),
                                        const Color(0xFF2E7D32),
                                        const AdminAppointmentsScreen(),
                                      ),
                                      _buildLogoutCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 26),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _sectionTitle("Recent Requests"),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        "${filteredDocs.length} Showing",
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                filteredDocs.isEmpty
                                    ? _buildEmptyState()
                                    : ListView.builder(
                                        itemCount: filteredDocs.length,
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          final data = _docData(filteredDocs[index]);

                                          final isCritical =
                                              (data['urgency'] ?? '')
                                                      .toString()
                                                      .toLowerCase() ==
                                                  'critical';

                                          final comingCount =
                                              (data['comingDonors'] as List? ?? [])
                                                  .length;

                                          return _buildAnimatedCard(
                                            delay: 100 + (index * 40),
                                            child: _buildRequestCard(
                                              docId: filteredDocs[index].id,
                                              data: data,
                                              patientName:
                                                  data['patientName'] ?? 'Unknown',
                                              hospitalName:
                                                  data['hospitalName'] ?? 'Hospital',
                                              bloodGroup: data['bloodGroup'] ?? '?',
                                              urgency: data['urgency'] ?? '',
                                              comingCount: comingCount,
                                              isCritical: isCritical,
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}