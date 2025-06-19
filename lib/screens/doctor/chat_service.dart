import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat.dart';
import 'encryption_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user details from users collection
  Future<Map<String, String>> getUserDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        return {
          'name': fullName.isNotEmpty ? fullName : 'User',
          'email': data['email'] ?? '',
          'type': 'user'
        };
      }
    } catch (e) {
      print('Error getting user details: $e');
    }
    return {'name': 'Unknown User', 'email': '', 'type': 'user'};
  }

  // Get doctor details from doctors collection
  Future<Map<String, String>> getDoctorDetails(String doctorId) async {
    try {
      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
      if (doctorDoc.exists) {
        final data = doctorDoc.data() as Map<String, dynamic>;
        return {
          'name': data['name'] ?? 'Dr. Unknown',
          'email': data['email'] ?? '',
          'specialization': data['specialization'] ?? '',
          'type': 'doctor'
        };
      }
    } catch (e) {
      print('Error getting doctor details: $e');
    }
    return {'name': 'Unknown Doctor', 'email': '', 'specialization': '', 'type': 'doctor'};
  }

  // Create or get existing chat with encryption
  Future<String> createChatIfNotExists({
    required String currentUserId,
    required String otherUserId,
    required String currentUserType,
    required String otherUserName,
  }) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in query.docs) {
        final participants = List<String>.from(doc['participants']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      final doctorId = currentUserType == 'user' ? otherUserId : currentUserId;
      final userId = currentUserType == 'user' ? currentUserId : otherUserId;

      final doctorDetails = await getDoctorDetails(doctorId);
      final userDetails = await getUserDetails(userId);

      final newChat = await _firestore.collection('chats').add({
        'userId': userId,
        'doctorId': doctorId,
        'doctorName': doctorDetails['name'],
        'userName': userDetails['name'],
        'doctorSpecialization': doctorDetails['specialization'],
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'encryptionKey': EncryptionService.generateKey(),
        'messages': [], // Initialize empty messages array
        'unreadCount': {
          userId: 0,
          doctorId: 0,
        }, // Track unread messages for each participant
      });

      return newChat.id;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  // Send message (directly updating the chat document)
  Future<void> sendMessage(
      String chatId,
      String senderId,
      String senderType,
      String content,
      ) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chat = Chat.fromFirestore(chatDoc);
      final encryptedContent = EncryptionService.encryptMessage(content, chat.encryptionKey);

      final message = {
        'senderId': senderId,
        'senderType': senderType,
        'encryptedContent': encryptedContent,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'messageId': _generateMessageId(), // Add unique message ID
      };

      // Get the other participant to increment their unread count
      final otherParticipantId = senderType == 'doctor' ? chat.userId : chat.doctorId;

      // Prepare update data
      final updateData = {
        'lastMessage': content.length > 50 ? '${content.substring(0, 50)}...' : content,
        'lastMessageTime': Timestamp.now(),
        'lastSenderId': senderId,
        'lastSenderType': senderType,
        'lastEncryptedMessage': encryptedContent,
        'messages': FieldValue.arrayUnion([message]),
        'unreadCount.$otherParticipantId': FieldValue.increment(1),
      };

      await _firestore.collection('chats').doc(chatId).update(updateData);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        return;
      }

      final data = chatDoc.data() as Map<String, dynamic>;
      final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);

      // Check if there are any unread messages from other participants
      bool hasUnreadMessages = false;
      final updatedMessages = messages.map((message) {
        if (message['senderId'] != userId && message['isRead'] == false) {
          hasUnreadMessages = true;
          return {...message, 'isRead': true};
        }
        return message;
      }).toList();

      // Only update if there are unread messages
      if (hasUnreadMessages) {
        await _firestore.collection('chats').doc(chatId).update({
          'messages': updatedMessages,
          'unreadCount.$userId': 0, // Reset unread count for this user
        });
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      int totalUnreadCount = 0;
      for (var doc in query.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
        if (unreadCount != null && unreadCount[userId] != null) {
          totalUnreadCount += (unreadCount[userId] as int);
        }
      }

      return totalUnreadCount;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Clear chat messages
  Future<void> clearChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'messages': [],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'lastSenderType': '',
        'lastEncryptedMessage': '',
      });
    } catch (e) {
      print('Error clearing chat: $e');
      rethrow;
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }

  // Get chat details
  Future<Chat?> getChatDetails(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        return Chat.fromFirestore(chatDoc);
      }
    } catch (e) {
      print('Error getting chat details: $e');
    }
    return null;
  }

  // Update typing status
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typing.$userId': isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
      });
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // Get typing status stream
  Stream<Map<String, bool>> getTypingStatus(String chatId, String currentUserId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String, bool>{};

      final data = doc.data() as Map<String, dynamic>;
      final typing = data['typing'] as Map<String, dynamic>? ?? {};
      final now = DateTime.now();

      return typing.entries
          .where((entry) => entry.key != currentUserId) // Exclude current user
          .fold<Map<String, bool>>({}, (map, entry) {
        if (entry.value is Timestamp) {
          final lastTypingTime = (entry.value as Timestamp).toDate();
          final isRecentlyTyping = now.difference(lastTypingTime).inSeconds < 5;
          if (isRecentlyTyping) {
            map[entry.key] = true;
          }
        }
        return map;
      });
    });
  }

  // Get chats for user with unread count
  Stream<List<Chat>> getChatsForUser(String userId) {
    return _firestore
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList());
  }

  // Get chats for doctor with unread count
  Stream<List<Chat>> getChatsForDoctor(String doctorId) {
    return _firestore
        .collection('chats')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList());
  }

  // Export chat messages
  Future<List<Map<String, dynamic>>> exportChatMessages(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        return [];
      }

      final chat = Chat.fromFirestore(chatDoc);
      final data = chatDoc.data() as Map<String, dynamic>;
      final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);

      return messages.map((message) {
        final decryptedContent = EncryptionService.decryptMessage(
          message['encryptedContent'],
          chat.encryptionKey,
        );

        return {
          'senderId': message['senderId'],
          'senderType': message['senderType'],
          'content': decryptedContent,
          'timestamp': message['timestamp'],
          'isRead': message['isRead'],
        };
      }).toList();
    } catch (e) {
      print('Error exporting chat: $e');
      return [];
    }
  }

  // Generate unique message ID
  String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString();
  }

  // Decrypt message
  String decryptMessage(String encryptedContent, String encryptionKey) {
    return EncryptionService.decryptMessage(encryptedContent, encryptionKey);
  }

  // Search messages in a chat
  Future<List<Map<String, dynamic>>> searchMessagesInChat(
      String chatId, String searchQuery) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        return [];
      }

      final chat = Chat.fromFirestore(chatDoc);
      final data = chatDoc.data() as Map<String, dynamic>;
      final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);

      final searchResults = <Map<String, dynamic>>[];

      for (var message in messages) {
        final decryptedContent = EncryptionService.decryptMessage(
          message['encryptedContent'],
          chat.encryptionKey,
        );

        if (decryptedContent.toLowerCase().contains(searchQuery.toLowerCase())) {
          searchResults.add({
            ...message,
            'decryptedContent': decryptedContent,
          });
        }
      }

      return searchResults;
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }
}