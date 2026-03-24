import 'package:flutter/material.dart';
import 'package:careeriq/models/chat.dart';
import 'package:careeriq/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  String? _currentChatRoomId;
  List<ChatMessage> _messages = [];

  String? get currentChatRoomId => _currentChatRoomId;
  List<ChatMessage> get messages => _messages;

  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _chatService.getChatRooms(userId);
  }

  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _chatService.getMessages(chatRoomId);
  }

  Future<void> sendMessage(String chatRoomId, String senderId, String content) async {
    final message = ChatMessage(
      id: '', // Will be set by Firestore
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
    );
    await _chatService.sendMessage(chatRoomId, message);
  }

  Future<String> getOrCreateChatRoom({
    required String userId,
    required String recruiterId,
    String? jobId,
    String? companyName,
    String? companyLogo,
  }) async {
    _currentChatRoomId = await _chatService.getOrCreateChatRoom(
      userId: userId,
      recruiterId: recruiterId,
      jobId: jobId,
      companyName: companyName,
      companyLogo: companyLogo,
    );
    notifyListeners();
    return _currentChatRoomId!;
  }

  Future<void> seedChatRooms(String userId) async {
    await _chatService.seedChatRooms(userId);
    notifyListeners();
  }
}
