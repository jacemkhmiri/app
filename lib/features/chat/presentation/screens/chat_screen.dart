import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../widgets/message_bubble.dart';
import '../../../../services/p2p_service.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  bool _otherUserOnline = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _initializeP2PConnection();
    _setupP2PListeners();
  }

  void _initializeP2PConnection() async {
    final p2pService = Provider.of<P2PService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser != null && p2pService.isConnected) {
      final recipientId = widget.chat.participantIds
          .firstWhere((id) => id != currentUser.id, orElse: () => '');
      if (recipientId.isNotEmpty) {
        await p2pService.startChat(widget.chat.id, recipientId);
      }
    }
  }

  void _setupP2PListeners() {
    final p2pService = Provider.of<P2PService>(context, listen: false);

    // Listen for incoming messages
    p2pService.onMessageReceived = (chatId, message) {
      if (chatId == widget.chat.id && mounted) {
        final newMessage = Message(
          id: message['id'],
          senderId: message['senderId'],
          content: message['content'],
          timestamp: DateTime.parse(message['timestamp']),
          isMe: false,
        );

        Provider.of<ChatProvider>(context, listen: false)
            .addMessage(widget.chat.id, newMessage);
      }
    };

    // Listen for typing status
    p2pService.onTypingStatusChanged = (chatId, isTyping) {
      if (chatId == widget.chat.id && mounted) {
        setState(() {
          _otherUserTyping = isTyping;
        });
      }
    };

    // Listen for online status
    p2pService.onUserStatusChanged = (userId, isOnline) {
      final recipientId = widget.chat.participantIds
          .firstWhere((id) => id != p2pService.currentUserId, orElse: () => '');
      if (userId == recipientId && mounted) {
        setState(() {
          _otherUserOnline = isOnline;
        });
      }
    };
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUser = userProvider.currentUser;

    final currentChat = chatProvider.chats.firstWhere(
      (chat) => chat.id == widget.chat.id,
      orElse: () => widget.chat,
    );

    final participantNames = _getParticipantNames(currentChat, userProvider, currentUser);

    return Scaffold(
      appBar: _buildAppBar(participantNames),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(currentChat),
          ),
          if (_otherUserTyping) _buildTypingIndicator(participantNames),
          _buildMessageInput(currentChat, currentUser),
        ],
      ),
    );
  }

  AppBar _buildAppBar(String participantNames) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(participantNames),
          if (_otherUserOnline)
            const Text(
              'Online',
              style: TextStyle(fontSize: 12, color: Colors.green),
            )
          else
            const Text(
              'Offline',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildMessagesList(Chat currentChat) {
    if (currentChat.messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet.\nStart the conversation!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemCount: currentChat.messages.length,
      itemBuilder: (context, index) {
        final message = currentChat.messages[currentChat.messages.length - 1 - index];
        return MessageBubble(message: message);
      },
    );
  }

  Widget _buildTypingIndicator(String participantNames) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            '${participantNames.split(', ').first} is typing...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(Chat currentChat, User? currentUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : () => _sendMessage(currentChat, currentUser),
            ),
          ),
        ],
      ),
    );
  }

  String _getParticipantNames(Chat chat, UserProvider userProvider, User? currentUser) {
    return chat.participantIds
        .where((id) => id != currentUser?.id)
        .map((id) {
      try {
        return userProvider.allUsers.firstWhere((u) => u.id == id).name;
      } catch (e) {
        return 'Unknown User';
      }
    }).join(', ');
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      _sendTypingIndicator();
    } else if (_messageController.text.isEmpty && _isTyping) {
      setState(() => _isTyping = false);
      _sendStopTypingIndicator();
    }
  }

  void _sendTypingIndicator() {
    final p2pService = Provider.of<P2PService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser != null) {
      final recipientId = widget.chat.participantIds
          .firstWhere((id) => id != currentUser.id, orElse: () => '');
      if (recipientId.isNotEmpty) {
        p2pService.sendTypingStatus(widget.chat.id, recipientId, true);
      }
    }
  }

  void _sendStopTypingIndicator() {
    final p2pService = Provider.of<P2PService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser != null) {
      final recipientId = widget.chat.participantIds
          .firstWhere((id) => id != currentUser.id, orElse: () => '');
      if (recipientId.isNotEmpty) {
        p2pService.sendTypingStatus(widget.chat.id, recipientId, false);
      }
    }
  }

  Future<void> _sendMessage(Chat currentChat, User? currentUser) async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || currentUser == null) return;

    setState(() => _isSending = true);

    try {
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUser.id,
        content: messageText,
        timestamp: DateTime.now(),
        isMe: true,
      );

      Provider.of<ChatProvider>(context, listen: false)
          .addMessage(currentChat.id, newMessage);

      _messageController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      final recipientId = currentChat.participantIds
          .firstWhere((id) => id != currentUser.id, orElse: () => '');
      if (recipientId.isNotEmpty) {
        final p2pService = Provider.of<P2PService>(context, listen: false);
        await p2pService.sendMessage(
          chatId: currentChat.id,
          recipientUserId: recipientId,
          content: newMessage.content,
          messageId: newMessage.id,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }
}