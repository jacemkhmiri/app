import 'package:flutter/foundation.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';

class ChatProvider with ChangeNotifier {
  final List<Chat> _chats = [];
  bool _hasInitialized = false;

  List<Chat> get chats => _chats;

  Future<void> initializeSampleData() async {
    if (_hasInitialized) return;
    _hasInitialized = true;

    final sampleChats = [
      Chat(
        id: 'chat_1',
        participantIds: ['user_alice', 'user_bob'],
        messages: [
          Message(
            id: 'msg_1',
            senderId: 'user_alice',
            content: 'Hey Bob! How are you doing?',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            isMe: false,
            isSeen: false,
          ),
          Message(
            id: 'msg_2',
            senderId: 'user_bob',
            content: 'Hi Alice! I\'m doing great, thanks for asking. How about you?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
            isMe: true,
            isSeen: true,
          ),
          Message(
            id: 'msg_3',
            senderId: 'user_alice',
            content: 'I\'m fantastic! Just working on this new P2P app. It\'s so exciting!',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            isMe: false,
            isSeen: false,
          ),
        ],
        lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Chat(
        id: 'chat_2',
        participantIds: ['user_charlie', 'user_diana'],
        messages: [
          Message(
            id: 'msg_4',
            senderId: 'user_charlie',
            content: 'Diana, have you seen the new features in the app?',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isMe: false,
            isSeen: false,
          ),
          Message(
            id: 'msg_5',
            senderId: 'user_diana',
            content: 'Yes! The messaging UI looks amazing. The bubbles are so clean!',
            timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
            isMe: true,
            isSeen: true,
          ),
        ],
        lastActivity: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      ),
    ];

    _chats.addAll(sampleChats);
    notifyListeners();
  }

  void addChat(Chat chat) {
    _chats.add(chat);
    notifyListeners();
  }

  void addMessage(String chatId, Message message) {
    try {
      final chatIndex = _chats.indexWhere((c) => c.id == chatId);
      if (chatIndex != -1) {
        final chat = _chats[chatIndex];
        final updatedMessages = List<Message>.from(chat.messages)..add(message);
        final updatedChat = Chat(
          id: chat.id,
          participantIds: chat.participantIds,
          messages: updatedMessages,
          lastActivity: DateTime.now(),
        );
        _chats[chatIndex] = updatedChat;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding message: $e');
    }
  }
}