import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/encryption_service.dart';

part 'database_models.g.dart'; // For Hive code generation

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String publicKey;

  @HiveField(3)
  final String privateKey; // Encrypted

  @HiveField(4)
  final String deviceId;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime lastSeen;

  @HiveField(7)
  final bool isOnline;

  UserModel({
    required this.id,
    required this.username,
    required this.publicKey,
    required this.privateKey,
    required this.deviceId,
    required this.createdAt,
    required this.lastSeen,
    required this.isOnline,
  });

  factory UserModel.create(String username) {
    const uuid = Uuid();
    final keyPair = EncryptionService.generateKeyPair();

    return UserModel(
      id: uuid.v4(),
      username: username,
      publicKey: keyPair.publicKey,
      privateKey: keyPair.privateKey,
      deviceId: uuid.v4(),
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
      isOnline: true,
    );
  }
}

@HiveType(typeId: 1)
class ChatModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<String> participantIds;

  @HiveField(2)
  final String chatType; // 'direct', 'group'

  @HiveField(3)
  final String? groupName;

  @HiveField(4)
  final String? groupImage;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime lastActivity;

  @HiveField(7)
  final String lastMessagePreview;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.chatType,
    this.groupName,
    this.groupImage,
    required this.createdAt,
    required this.lastActivity,
    required this.lastMessagePreview,
  });

  factory ChatModel.directChat(List<String> participantIds) {
    const uuid = Uuid();
    return ChatModel(
      id: uuid.v4(),
      participantIds: participantIds,
      chatType: 'direct',
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
      lastMessagePreview: '',
    );
  }
}

@HiveType(typeId: 2)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final String messageType; // 'text', 'image', 'video', 'file'

  @HiveField(5)
  final String? mediaUrl;

  @HiveField(6)
  final String? fileSize;

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  final String status; // 'sending', 'sent', 'delivered', 'read'

  @HiveField(9)
  final String encryptionKey; // Key used to encrypt this message

  @HiveField(10)
  final bool isEncrypted;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.mediaUrl,
    this.fileSize,
    required this.timestamp,
    required this.status,
    required this.encryptionKey,
    required this.isEncrypted,
  });

  factory MessageModel.textMessage({
    required String chatId,
    required String senderId,
    required String content,
    required String encryptionKey,
  }) {
    return MessageModel(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      content: content,
      messageType: 'text',
      timestamp: DateTime.now(),
      status: 'sending',
      encryptionKey: encryptionKey,
      isEncrypted: true,
    );
  }
}

@HiveType(typeId: 3)
class PostModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String? mediaUrl;

  @HiveField(4)
  final String postType; // 'text', 'image', 'video'

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final int likes;

  @HiveField(7)
  final List<String> likedBy;

  @HiveField(8)
  final List<CommentModel> comments;

  @HiveField(9)
  final bool isEncrypted;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrl,
    required this.postType,
    required this.timestamp,
    required this.likes,
    required this.likedBy,
    required this.comments,
    required this.isEncrypted,
  });
}

@HiveType(typeId: 4)
class CommentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String postId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.timestamp,
  });
}

@HiveType(typeId: 5)
class DiscoveryModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String deviceId;

  @HiveField(2)
  final String publicKey;

  @HiveField(3)
  final String ipAddress;

  @HiveField(4)
  final DateTime lastDiscovered;

  @HiveField(5)
  final bool isTrusted;

  DiscoveryModel({
    required this.userId,
    required this.deviceId,
    required this.publicKey,
    required this.ipAddress,
    required this.lastDiscovered,
    required this.isTrusted,
  });
}
