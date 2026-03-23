import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Create: අලුත් Request එකක් දාන්න
  Future<String?> addBloodRequest(RequestModel request) async {
    try {
      // Auto-generated ID එකක් එක්ක save කරනවා
      await _firestore.collection('requests').add(request.toMap());
      return "Success";
    } catch (e) {
      return e.toString();
    }
  }

  // 2. Read: Requests ඔක්කොම ගන්න (Stream එකක් විදියට - Realtime)
  Stream<List<RequestModel>> getRequests() {
    return _firestore
        .collection('requests')
        .orderBy('createdAt', descending: true) // අලුත් ඒවා උඩින් පෙන්වන්න
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // 3. Update Status (Admin can mark as Completed)
  Future<void> updateRequestStatus(String id, String newStatus) async {
    await _firestore.collection('requests').doc(id).update({
      'status': newStatus,
    });
  }

  // 4. Donor Commits (I am Coming Button එක සඳහා) - [NEW]
  Future<void> donorCommits(String requestId, String userId) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        // arrayUnion පාවිච්චි කරන්නේ එකම කෙනා දෙපාරක් add වෙන එක නවත්වන්න
        // 'comingDonors' කියන field එකට user id එක එකතු කරනවා
        'comingDonors': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print("Error committing donor: $e");
    }
  }
}