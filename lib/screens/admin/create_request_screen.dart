import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _patientNameController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _noteController = TextEditingController();

  final Color primaryRed = const Color(0xFFD32F2F);
  final Color darkRed = const Color(0xFFB71C1C);
  final Color softBg = const Color(0xFFF6F8FB);

  String _selectedBloodGroup = 'A+';
  String _urgency = 'Normal';
  bool _isLoading = false;

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    _hospitalNameController.dispose();
    _contactController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'patientName': _patientNameController.text.trim(),
        'hospitalName': _hospitalNameController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'urgency': _urgency,
        'contactNumber': _contactController.text.trim(),
        'note': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'comingDonors': [],
      });

      await NotificationService().sendNotificationToAll(
        _selectedBloodGroup,
        _hospitalNameController.text.trim(),
      );

      if (!mounted) return;

      _showSnackBar(
        "Request posted successfully and donors notified.",
        Colors.green,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Failed to create request: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return "$label is required";
    }
    return null;
  }

  String? _validateContact(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Emergency contact is required";
    }

    final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleaned.length < 10) {
      return "Enter a valid contact number";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: softBg,
      body: Stack(
        children: [
          _buildTopHeader(size),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: size.height * 0.20,
                left: 18,
                right: 18,
                bottom: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(Size size) {
    return Container(
      height: size.height * 0.29,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkRed, primaryRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                      "Create Blood Request",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: const Icon(
                  Icons.emergency_share_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Fill the patient details and notify matching donors instantly",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Patient Information"),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _patientNameController,
            hint: "Patient full name",
            icon: Icons.person_outline_rounded,
            validator: (value) => _validateRequired(value, "Patient name"),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _hospitalNameController,
            hint: "Hospital name",
            icon: Icons.local_hospital_outlined,
            validator: (value) => _validateRequired(value, "Hospital name"),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _contactController,
            hint: "Emergency contact number",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _validateContact,
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 20),
          _sectionTitle("Request Details"),
          const SizedBox(height: 14),
          _buildLabel("Blood Group"),
          const SizedBox(height: 10),
          _buildBloodGroupSelector(),
          const SizedBox(height: 18),
          _buildLabel("Priority Level"),
          const SizedBox(height: 10),
          _buildUrgencySelector(),
          const SizedBox(height: 18),
          _buildLabel("Additional Note"),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _noteController,
            hint: "Any special instructions or important note...",
            icon: Icons.note_alt_outlined,
            maxLines: 4,
            validator: (_) => null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _urgency == 'Critical'
              ? Colors.red.withOpacity(0.15)
              : Colors.grey.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Request Preview"),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _urgency == 'Critical'
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _selectedBloodGroup,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _urgency == 'Critical'
                          ? primaryRed
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
                      _patientNameController.text.trim().isEmpty
                          ? "Patient name"
                          : _patientNameController.text.trim(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hospitalNameController.text.trim().isEmpty
                          ? "Hospital name"
                          : _hospitalNameController.text.trim(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(
                text: _urgency,
                bg: _urgency == 'Critical'
                    ? Colors.red.withOpacity(0.10)
                    : Colors.green.withOpacity(0.10),
                fg: _urgency == 'Critical'
                    ? Colors.red.shade700
                    : Colors.green.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          disabledBackgroundColor: primaryRed.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 8,
          shadowColor: primaryRed.withOpacity(0.25),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.6,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_active_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "POST REQUEST & NOTIFY DONORS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBloodGroupSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _bloodGroups.map((group) {
        final isSelected = _selectedBloodGroup == group;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedBloodGroup = group);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryRed : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? primaryRed : Colors.grey.shade300,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              group,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUrgencySelector() {
    return Row(
      children: [
        Expanded(
          child: _buildUrgencyOption(
            label: "Normal",
            icon: Icons.check_circle_outline_rounded,
            isSelected: _urgency == 'Normal',
            selectedBg: const Color(0xFFE8F5E9),
            selectedFg: Colors.green.shade700,
            borderColor: Colors.green.shade200,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildUrgencyOption(
            label: "Critical",
            icon: Icons.warning_amber_rounded,
            isSelected: _urgency == 'Critical',
            selectedBg: const Color(0xFFFFEBEE),
            selectedFg: Colors.red.shade700,
            borderColor: Colors.red.shade200,
          ),
        ),
      ],
    );
  }

  Widget _buildUrgencyOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color selectedBg,
    required Color selectedFg,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _urgency = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? borderColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? selectedFg : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedFg : Colors.grey[700],
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}