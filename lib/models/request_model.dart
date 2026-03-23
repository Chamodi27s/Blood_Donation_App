import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String requestedBy; // Admin ID
  final String patientName;
  final String bloodGroup;
  final String urgency; // 'Critical', 'High', 'Medium'
  final String hospitalName;
  final String contactNumber;
  final String status; // 'Pending', 'Fulfilled'
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.requestedBy,
    required this.patientName,
    required this.bloodGroup,
    required this.urgency,
    required this.hospitalName,
    required this.contactNumber,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestedBy': requestedBy,
      'patientName': patientName,
      'bloodGroup': bloodGroup,
      'urgency': urgency,
      'hospitalName': hospitalName,
      'contactNumber': contactNumber,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return RequestModel(
      id: docId,
      requestedBy: map['requestedBy'] ?? '',
      patientName: map['patientName'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      urgency: map['urgency'] ?? 'Medium',
      hospitalName: map['hospitalName'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}