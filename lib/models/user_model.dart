class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;       // 'admin' or 'donor'
  final String bloodGroup; // 'A+', 'O-' etc.
  final bool isAvailable;  // ලේ දෙන්න කැමතිද?

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.bloodGroup,
    this.isAvailable = true, // Default value එක true
  });

  // Data -> Firebase යවන්න (Map එකක් විදියට)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'bloodGroup': bloodGroup,
      'isAvailable': isAvailable,
    };
  }

  // Firebase -> Data ගන්න (Object එකක් විදියට)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'donor',
      bloodGroup: map['bloodGroup'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}