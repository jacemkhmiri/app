// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      username: fields[1] as String,
      publicKey: fields[2] as String,
      privateKey: fields[3] as String,
      deviceId: fields[4] as String,
      createdAt: fields[5] as DateTime,
      lastSeen: fields[6] as DateTime,
      isOnline: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.publicKey)
      ..writeByte(3)
      ..write(obj.privateKey)
      ..writeByte(4)
      ..write(obj.deviceId)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastSeen)
      ..writeByte(7)
      ..write(obj.isOnline);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatModelAdapter extends TypeAdapter<ChatModel> {
  @override
  final int typeId = 1;

  @override
  ChatModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatModel(
      id: fields[0] as String,
      participantIds: (fields[1] as List).cast<String>(),
      chatType: fields[2] as String,
      groupName: fields[3] as String?,
      groupImage: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      lastActivity: fields[6] as DateTime,
      lastMessagePreview: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChatModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.participantIds)
      ..writeByte(2)
      ..write(obj.chatType)
      ..writeByte(3)
      ..write(obj.groupName)
      ..writeByte(4)
      ..write(obj.groupImage)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastActivity)
      ..writeByte(7)
      ..write(obj.lastMessagePreview);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 2;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String,
      chatId: fields[1] as String,
      senderId: fields[2] as String,
      content: fields[3] as String,
      messageType: fields[4] as String,
      mediaUrl: fields[5] as String?,
      fileSize: fields[6] as String?,
      timestamp: fields[7] as DateTime,
      status: fields[8] as String,
      encryptionKey: fields[9] as String,
      isEncrypted: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chatId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.messageType)
      ..writeByte(5)
      ..write(obj.mediaUrl)
      ..writeByte(6)
      ..write(obj.fileSize)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.encryptionKey)
      ..writeByte(10)
      ..write(obj.isEncrypted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PostModelAdapter extends TypeAdapter<PostModel> {
  @override
  final int typeId = 3;

  @override
  PostModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      content: fields[2] as String,
      mediaUrl: fields[3] as String?,
      postType: fields[4] as String,
      timestamp: fields[5] as DateTime,
      likes: fields[6] as int,
      likedBy: (fields[7] as List).cast<String>(),
      comments: (fields[8] as List).cast<CommentModel>(),
      isEncrypted: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PostModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.mediaUrl)
      ..writeByte(4)
      ..write(obj.postType)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.likes)
      ..writeByte(7)
      ..write(obj.likedBy)
      ..writeByte(8)
      ..write(obj.comments)
      ..writeByte(9)
      ..write(obj.isEncrypted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CommentModelAdapter extends TypeAdapter<CommentModel> {
  @override
  final int typeId = 4;

  @override
  CommentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommentModel(
      id: fields[0] as String,
      postId: fields[1] as String,
      userId: fields[2] as String,
      content: fields[3] as String,
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CommentModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.postId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscoveryModelAdapter extends TypeAdapter<DiscoveryModel> {
  @override
  final int typeId = 5;

  @override
  DiscoveryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiscoveryModel(
      userId: fields[0] as String,
      deviceId: fields[1] as String,
      publicKey: fields[2] as String,
      ipAddress: fields[3] as String,
      lastDiscovered: fields[4] as DateTime,
      isTrusted: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DiscoveryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.deviceId)
      ..writeByte(2)
      ..write(obj.publicKey)
      ..writeByte(3)
      ..write(obj.ipAddress)
      ..writeByte(4)
      ..write(obj.lastDiscovered)
      ..writeByte(5)
      ..write(obj.isTrusted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
