import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageCampaignsScreen extends StatefulWidget {
  const ManageCampaignsScreen({super.key});

  @override
  State<ManageCampaignsScreen> createState() => _ManageCampaignsScreenState();
}

class _ManageCampaignsScreenState extends State<ManageCampaignsScreen> {
  final Color primaryRed = const Color(0xFFD32F2F);
  final Color darkRed = const Color(0xFFB71C1C);
  final Color softBg = const Color(0xFFF6F8FB);

  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Upcoming', 'Past'];

  List<QueryDocumentSnapshot> _filterCampaigns(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final location = (data['location'] ?? '').toString().toLowerCase();
      final search = _searchQuery.toLowerCase();

      final matchesSearch =
          search.isEmpty || name.contains(search) || location.contains(search);

      bool matchesFilter = true;

      if (data['date'] is Timestamp) {
        final date = (data['date'] as Timestamp).toDate();

        if (_selectedFilter == 'Upcoming') {
          matchesFilter = date.isAfter(
            DateTime(now.year, now.month, now.day - 1, 23, 59),
          );
        } else if (_selectedFilter == 'Past') {
          matchesFilter = date.isBefore(
            DateTime(now.year, now.month, now.day),
          );
        }
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  String _campaignStatus(DateTime date) {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final campaignOnly = DateTime(date.year, date.month, date.day);

    if (campaignOnly == todayOnly) return 'Today';
    if (date.isBefore(todayOnly)) return 'Past';
    return 'Upcoming';
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _deleteCampaign(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('campaigns').doc(docId).delete();
      if (!mounted) return;
      _showSnackBar("Campaign deleted successfully.", Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Failed to delete campaign.", Colors.redAccent);
    }
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Delete Campaign?"),
        content: const Text("This event will be removed permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteCampaign(docId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  void _showCampaignDetails({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final Timestamp? ts = data['date'] as Timestamp?;
    final DateTime? date = ts?.toDate();
    final name = (data['name'] ?? 'Blood Donation Camp').toString();
    final location = (data['location'] ?? 'Location not set').toString();
    final status = date != null ? _campaignStatus(date) : 'Upcoming';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusBadgeForStatus(status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow(Icons.location_on_outlined, "Location", location),
                _detailRow(
                  Icons.calendar_today_outlined,
                  "Date",
                  date != null
                      ? DateFormat('EEEE, d MMMM yyyy').format(date)
                      : 'No date',
                ),
                _detailRow(
                  Icons.access_time_rounded,
                  "Time",
                  date != null ? DateFormat('jm').format(date) : 'No time',
                ),
                const SizedBox(height: 16),
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
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
    );
  }

  void _addNewCamp() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final finalDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 26,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Create Campaign",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Organize and publish a new blood donation event.",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildInput(
                        controller: nameController,
                        hint: "Campaign name",
                        icon: Icons.campaign_rounded,
                      ),
                      const SizedBox(height: 14),
                      _buildInput(
                        controller: locationController,
                        hint: "Location",
                        icon: Icons.location_on_rounded,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Date & Time",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setModalState(() => selectedDate = picked);
                                }
                              },
                              icon: Icon(
                                Icons.calendar_month_rounded,
                                color: primaryRed,
                                size: 20,
                              ),
                              label: Text(
                                DateFormat('MMM dd, yyyy').format(selectedDate),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setModalState(() => selectedTime = picked);
                                }
                              },
                              icon: Icon(
                                Icons.access_time_rounded,
                                color: primaryRed,
                                size: 20,
                              ),
                              label: Text(
                                selectedTime.format(context),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.event_available_rounded,
                                color: primaryRed,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${DateFormat('EEEE, d MMM yyyy').format(finalDateTime)} • ${DateFormat('jm').format(finalDateTime)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty ||
                                      locationController.text.trim().isEmpty) {
                                    _showSnackBar(
                                      "Please fill all fields.",
                                      Colors.redAccent,
                                    );
                                    return;
                                  }

                                  setModalState(() => isLoading = true);

                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('campaigns')
                                        .add({
                                      'name': nameController.text.trim(),
                                      'location': locationController.text.trim(),
                                      'date': Timestamp.fromDate(finalDateTime),
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    _showSnackBar(
                                      "Campaign published successfully.",
                                      Colors.green,
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    _showSnackBar(
                                      "Failed to publish campaign.",
                                      Colors.redAccent,
                                    );
                                  } finally {
                                    if (context.mounted) {
                                      setModalState(() => isLoading = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 6,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text(
                                  "PUBLISH EVENT",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryRed.withOpacity(0.25)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildAnimatedCard({required Widget child, int delay = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.94, end: 1),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
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

  Widget _buildStatusBadgeForStatus(String status) {
    Color bg;
    Color fg;

    if (status == 'Today') {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFEF6C00);
    } else if (status == 'Past') {
      bg = Colors.grey.withOpacity(0.12);
      fg = Colors.grey.shade700;
    } else {
      bg = Colors.green.withOpacity(0.10);
      fg = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: _cardDecoration(),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value.trim());
        },
        decoration: InputDecoration(
          hintText: "Search campaign or location...",
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
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
            borderSide: BorderSide(color: primaryRed.withOpacity(0.2)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
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
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
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
              Icons.event_note_rounded,
              size: 34,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "No Campaigns Found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Try changing the search or filter options.",
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

  Widget _buildCampaignCard({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final Timestamp? t = data['date'] as Timestamp?;
    final DateTime? date = t?.toDate();

    final day = date != null ? DateFormat('dd').format(date) : '--';
    final month = date != null ? DateFormat('MMM').format(date) : '--';
    final fullDate =
        date != null ? DateFormat('EEEE, d MMMM yyyy').format(date) : 'No date';
    final time = date != null ? DateFormat('jm').format(date) : 'No time';
    final status = date != null ? _campaignStatus(date) : 'Upcoming';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showCampaignDetails(docId: docId, data: data),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Container(
                height: 148,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.volunteer_activism_rounded,
                        size: 62,
                        color: Colors.red.withOpacity(0.18),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _buildStatusBadgeForStatus(status),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              day,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: primaryRed,
                              ),
                            ),
                            Text(
                              month.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (data['name'] ?? 'Blood Donation Camp').toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onSelected: (value) {
                            if (value == 'view') {
                              _showCampaignDetails(docId: docId, data: data);
                            } else if (value == 'delete') {
                              _confirmDelete(docId);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'view',
                              child: Text("View Details"),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text("Delete"),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fullDate,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (data['location'] ?? 'Location not set').toString(),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader({
    required int total,
    required int upcoming,
    required int past,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
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
            color: primaryRed.withOpacity(0.22),
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
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Manage Campaigns",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: _addNewCamp,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  "Create and manage blood donation campaigns with date, time, and location details.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderMini("Total", "$total"),
                _dividerWhite(),
                _buildHeaderMini("Upcoming", "$upcoming"),
                _dividerWhite(),
                _buildHeaderMini("Past", "$past"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMini(String label, String value) {
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
      color: Colors.white.withOpacity(0.24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCamp,
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "New Camp",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('campaigns')
              .orderBy('date', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: primaryRed),
              );
            }

            if (snapshot.hasError) {
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

            final docs = snapshot.data?.docs ?? [];
            final filteredDocs = _filterCampaigns(docs);
            final now = DateTime.now();

            final upcomingCount = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['date'] is! Timestamp) return false;
              final date = (data['date'] as Timestamp).toDate();
              final todayOnly = DateTime(now.year, now.month, now.day);
              return !date.isBefore(todayOnly);
            }).length;

            final pastCount = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['date'] is! Timestamp) return false;
              final date = (data['date'] as Timestamp).toDate();
              final todayOnly = DateTime(now.year, now.month, now.day);
              return date.isBefore(todayOnly);
            }).length;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildTopHeader(
                    total: docs.length,
                    upcoming: upcomingCount,
                    past: pastCount,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAnimatedCard(
                          delay: 40,
                          child: _buildSearchBar(),
                        ),
                        const SizedBox(height: 12),
                        _buildAnimatedCard(
                          delay: 80,
                          child: _buildFilterChips(),
                        ),
                        const SizedBox(height: 18),
                        _buildAnimatedCard(
                          delay: 110,
                          child: Row(
                            children: [
                              _buildStatCard(
                                "Total",
                                "${docs.length}",
                                Icons.campaign_rounded,
                                const Color(0xFF1565C0),
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                "Upcoming",
                                "$upcomingCount",
                                Icons.upcoming_rounded,
                                const Color(0xFF2E7D32),
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                "Past",
                                "$pastCount",
                                Icons.history_rounded,
                                const Color(0xFFEF6C00),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionTitle("Campaign Events"),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryRed.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                "${filteredDocs.length} Showing",
                                style: TextStyle(
                                  color: primaryRed,
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
                                  final data = filteredDocs[index].data()
                                      as Map<String, dynamic>;

                                  return _buildAnimatedCard(
                                    delay: 100 + (index * 40),
                                    child: _buildCampaignCard(
                                      docId: filteredDocs[index].id,
                                      data: data,
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
        ),
      ),
    );
  }
}