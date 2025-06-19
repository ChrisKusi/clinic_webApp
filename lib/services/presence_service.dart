import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  void setupPresence() async {
    if (_userId == null) {
      print('No user logged in, cannot set up presence');
      return;
    }

    final presenceRef = _firestore.collection('presence').doc(_userId);

    try {
      print('Setting up presence for user: $_userId');
      // Set online status
      await presenceRef.set({
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }).catchError((error) {
        print('Error setting online status: $error');
      });

      // Simulate onDisconnect by updating on app close (approximation)
      // Note: Firestore doesn't natively support onDisconnect
      print('Presence set: online for user $_userId');
    } catch (e) {
      print('Setup presence error: $e');
    }
  }

  Stream<Map<String, dynamic>?> getPresenceStream(String userId) {
    try {
      print('Fetching presence stream for user: $userId');
      return _firestore.collection('presence').doc(userId).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (data == null) {
          print('No presence data for user: $userId');
          return null;
        }
        return {
          'online': data['online'] as bool,
          'lastSeen': (data['lastSeen'] as Timestamp).millisecondsSinceEpoch,
        };
      }).handleError((error) {
        print('Error streaming presence for $userId: $error');
        return null;
      });
    } catch (e) {
      print('Get presence stream error: $e');
      return Stream.value(null);
    }
  }
}