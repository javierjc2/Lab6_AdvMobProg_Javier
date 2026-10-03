import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';

/// Firestore layout used by the chat feature:
///
///   users/{uid}                              -> profile docs written at sign-up
///   chat_rooms/{uidA_uidB}/messages/{id}     -> the messages of one 1-to-1 chat
///
/// The chat room id is the two user ids, sorted and joined with "_", so both
/// participants always resolve to the same room.
class ChatService {
  // Getters (not fields) so Firebase is only touched after initializeApp().
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  /// uid of the signed-in Firebase user (null for DummyJSON sessions).
  String? get currentUid => _firebaseAuth.currentUser?.uid;

  // ---------------------------------------------------------------- helpers

  static String chatRoomId(String userA, String userB) {
    final ids = [userA, userB]..sort(); // same id for any 2 users
    return ids.join('_');
  }

  /// Best human-readable name for a `users/{uid}` map.
  static String displayName(Map<String, dynamic> user) {
    final first = (user['fName'] ?? user['firstName'] ?? '').toString().trim();
    final last = (user['lName'] ?? user['lastName'] ?? '').toString().trim();
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;

    final username = (user['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;

    final email = (user['email'] ?? '').toString().trim();
    if (email.isEmpty) return 'Unknown';
    return email.contains('@') ? email.split('@').first : email;
  }

  // ------------------------------------------------------------------ users

  /// Enhancement 1: every registered user EXCEPT the logged-in one,
  /// sorted by name. Each map also carries the document id as `uid`.
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final me = currentUid;
      final users = snapshot.docs
          .where((doc) => doc.id != me)
          .map((doc) => <String, dynamic>{...doc.data(), 'uid': doc.id})
          .toList();

      users.sort(
        (a, b) => displayName(a).toLowerCase().compareTo(
          displayName(b).toLowerCase(),
        ),
      );
      return users;
    });
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.id; // the document id IS the Firebase Auth uid
  }

  // --------------------------------------------------------------- messages

  /// Adds a message to the chat room. Firestore writes to its local cache
  /// first, so the message shows up instantly as "pending" and flips to
  /// "delivered" once the server acknowledges it.
  Future<void> sendMessage(String receiverId, String message) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Chat needs a Firebase account. Please sign in again.');
    }

    final newMessage = MessageModel(
      senderId: user.uid,
      senderEmail: user.email ?? '',
      receiverId: receiverId,
      message: message,
      timestamp: Timestamp.now(),
    );

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId(user.uid, receiverId))
        .collection('messages')
        .add(newMessage.toMap());
  }

  /// Live messages of a conversation, newest first. Metadata changes are
  /// included so the UI can tell "pending write" from "acknowledged".
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessage(
    String userId,
    String otherUserId,
  ) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId(userId, otherUserId))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  /// Flags every incoming, not-yet-seen message as read ("Seen").
  Future<void> markMessagesAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final me = currentUid;
    if (me == null) return;

    final unread = docs.where((d) {
      final data = d.data();
      return data['receiverId'] == me &&
          data['isRead'] != true &&
          !d.metadata.hasPendingWrites;
    }).toList();
    if (unread.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (final d in unread) {
        batch.update(d.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {
      // Non-critical: it will be retried on the next snapshot.
    }
  }
}
