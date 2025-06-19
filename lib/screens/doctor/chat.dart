import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String doctorId;
  final String userId;
  final String doctorName;
  final String userName;
  final String doctorSpecialization;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String encryptionKey;

  Chat({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.doctorName,
    required this.userName,
    this.doctorSpecialization = '',
    required this.lastMessage,
    required this.lastMessageTime,
    required this.encryptionKey,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      userId: data['userId'] ?? '',
      doctorName: data['doctorName'] ?? 'Unknown Doctor',
      userName: data['userName'] ?? 'Unknown User',
      doctorSpecialization: data['doctorSpecialization'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      encryptionKey: data['encryptionKey'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'userId': userId,
      'doctorName': doctorName,
      'userName': userName,
      'doctorSpecialization': doctorSpecialization,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'encryptionKey': encryptionKey,
    };
  }
}