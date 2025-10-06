import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/database_models.dart';

class DatabaseService {
  static late Box<UserModel> userBox;
  static late Box<ChatModel> chatBox;
  static late Box<MessageModel> messageBox;
  static late Box<PostModel> postBox;
  static late Box<DiscoveryModel> discoveryBox;

  static Future<void> init() async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
    }

    // Register adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(ChatModelAdapter());
    Hive.registerAdapter(MessageModelAdapter());
    Hive.registerAdapter(PostModelAdapter());
    Hive.registerAdapter(DiscoveryModelAdapter());
    Hive.registerAdapter(CommentModelAdapter());

    // Open boxes
    userBox = await Hive.openBox<UserModel>('users');
    chatBox = await Hive.openBox<ChatModel>('chats');
    messageBox = await Hive.openBox<MessageModel>('messages');
    postBox = await Hive.openBox<PostModel>('posts');
    discoveryBox = await Hive.openBox<DiscoveryModel>('discoveries');
  }

  // User operations
  static Future<void> saveUser(UserModel user) async {
    await userBox.put(user.id, user);
  }

  static UserModel? getCurrentUser() {
    try {
      return userBox.values.firstWhere(
        (user) => user.deviceId == _getDeviceId(),
      );
    } catch (_) {
      return null;
    }
  }

  static List<UserModel> getDiscoveredUsers() {
    final discoveries = discoveryBox.values.toList();
    return discoveries
        .map((discovery) {
          return userBox.get(discovery.userId);
        })
        .whereType<UserModel>()
        .toList();
  }

  // Chat operations
  static Future<void> saveChat(ChatModel chat) async {
    await chatBox.put(chat.id, chat);
  }

  static List<ChatModel> getUserChats(String userId) {
    return chatBox.values.where((chat) {
      return chat.participantIds.contains(userId);
    }).toList();
  }

  // Message operations
  static Future<void> saveMessage(MessageModel message) async {
    await messageBox.put(message.id, message);

    // Update chat last activity and preview
    final chat = chatBox.get(message.chatId);
    if (chat != null) {
      final updatedChat = ChatModel(
        id: chat.id,
        participantIds: chat.participantIds,
        chatType: chat.chatType,
        groupName: chat.groupName,
        groupImage: chat.groupImage,
        createdAt: chat.createdAt,
        lastActivity: DateTime.now(),
        lastMessagePreview: message.content,
      );
      await chatBox.put(chat.id, updatedChat);
    }
  }

  static List<MessageModel> getChatMessages(String chatId) {
    return messageBox.values
        .where((message) => message.chatId == chatId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Post operations
  static Future<void> savePost(PostModel post) async {
    await postBox.put(post.id, post);
  }

  static List<PostModel> getFeedPosts() {
    return postBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Discovery operations
  static Future<void> saveDiscovery(DiscoveryModel discovery) async {
    await discoveryBox.put(discovery.userId, discovery);
  }

  static String _getDeviceId() {
    // In production, use device_info_plus package
    return 'device_id_placeholder';
  }

  static Future<void> clearAllData() async {
    await userBox.clear();
    await chatBox.clear();
    await messageBox.clear();
    await postBox.clear();
    await discoveryBox.clear();
  }
}
