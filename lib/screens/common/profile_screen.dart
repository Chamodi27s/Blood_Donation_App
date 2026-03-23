import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _bloodGroup = "-";
  String _userName = "";
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (user != null) {
      try {
        var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _userName = data['name'] ?? '';
            _bloodGroup = data['bloodGroup'] ?? '-';
            _isFetching = false;
          });
        }
      } catch (e) {
        setState(() => _isFetching = false);
      }
    }
  }

  String _getInitial(String name) {
    if (name.isEmpty) return "U";
    return name.trim()[0].toUpperCase();
  }

  void _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar("Name cannot be empty", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      setState(() => _userName = _nameController.text.trim());
      if (mounted) _showSnackBar("Profile Updated Successfully!", Colors.green);
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", Colors.redAccent);
    }
    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // --- 1. USER AVATAR & INFO ---
            _buildProfileHeader(),
            const SizedBox(height: 30),

            // --- 2. PERSONAL INFO CARD ---
            _buildInfoCard(),
            const SizedBox(height: 25),

            // --- 3. SAVE BUTTON ---
            _buildSaveButton(),

            const SizedBox(height: 15),

            // --- 4. LOGOUT OPTION ---
            TextButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.grey),
              label: const Text("Logout from Account", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFC62828), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
            ],
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Text(
              _getInitial(_userName),
              style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(_userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2D3436))),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge("Blood Group: $_bloodGroup", Colors.red[50]!, Colors.red[900]!),
            const SizedBox(width: 8),
            _buildBadge("Verified", Colors.green[50]!, Colors.green[900]!),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel("FULL NAME"),
          _buildTextField(_nameController, Icons.person_rounded),
          const SizedBox(height: 20),
          _buildInputLabel("PHONE NUMBER"),
          _buildTextField(_phoneController, Icons.phone_iphone_rounded, isPhone: true),
          const SizedBox(height: 20),
          _buildInputLabel("EMAIL ADDRESS"),
          _buildReadOnlyField(user?.email ?? "", Icons.alternate_email_rounded),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.grey, fontSize: 11, letterSpacing: 1.2));
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, {bool isPhone = false}) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFC62828), size: 22),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC62828), width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  Widget _buildReadOnlyField(String value, IconData icon) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 22),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFF0F0F0))),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          shadowColor: Colors.red.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
      ),
    );
  }
}