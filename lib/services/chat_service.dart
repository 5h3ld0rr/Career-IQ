import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:careeriq/models/chat.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatRoom.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> sendMessage(String chatRoomId, ChatMessage message) async {
    final batch = _firestore.batch();

    final messageRef = _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc();

    batch.set(messageRef, message.toMap());

    final chatRef = _firestore.collection('chats').doc(chatRoomId);
    batch.update(chatRef, {
      'lastMessage': message.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<String> getOrCreateChatRoom({
    required String userId,
    required String recruiterId,
    String? jobId,
    String? companyName,
    String? companyLogo,
  }) async {
    // Check if a chat room already exists between these two for this job
    // Simplified: checking for any chat between these two
    final existing = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    for (var doc in existing.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(recruiterId)) {
        return doc.id;
      }
    }

    // Create new chat room if not exists
    final docRef = _firestore.collection('chats').doc();
    final newRoom = ChatRoom(
      id: docRef.id,
      participants: [userId, recruiterId],
      lastMessage: 'Chat started',
      lastMessageTime: DateTime.now(),
      jobId: jobId,
      companyName: companyName,
      companyLogo: companyLogo,
    );

    await docRef.set(newRoom.toMap());
    return docRef.id;
  }

  Future<void> seedChatRooms(String userId) async {
    const recruiterId = 'mock_recruiter_id';
    final roomId = await getOrCreateChatRoom(
      userId: userId,
      recruiterId: recruiterId,
      companyName: 'TechCorp Solutions',
      companyLogo: 'https://cdn-icons-png.flaticon.com/512/281/281764.png',
      jobId: 'job_001',
    );

    await sendMessage(
      roomId,
      ChatMessage(
        id: '',
        senderId: recruiterId,
        content:
            'Hello! I saw your application. Are you free for a call tomorrow?',
        timestamp: DateTime.now(),
      ),
    );
  }
}
