import '../entities/chat.dart';
import '../entities/message.dart';
import '../../../../core/errors/failures.dart';

abstract class ChatRepository {
  Future<({Failure? failure, List<Chat>? data})> getChats();
  Future<({Failure? failure, Chat? data})> getChatById(String id);
  Future<({Failure? failure, Chat? data})> createChat(Chat chat);
  Future<({Failure? failure, List<Message>? data})> getChatMessages(String chatId);
  Future<({Failure? failure, Message? data})> sendMessage(String chatId, Message message);
  Future<({Failure? failure, bool? data})> markAsRead(String chatId);
  Future<({Failure? failure, bool? data})> deleteChat(String chatId);
  Future<({Failure? failure, List<Chat>? data})> getSampleChats();
}
