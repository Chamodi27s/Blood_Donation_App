// File: lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  // Database එකෙන් User විස්තර ගන්න Function එක
  Future<void> fetchUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _isLoading = true;
      notifyListeners();

      try {
        DocumentSnapshot snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        _userModel = UserModel.fromMap(snap.data() as Map<String, dynamic>);
      } catch (e) {
        print(e.toString());
      }

      _isLoading = false;
      notifyListeners();
    }
  }
}