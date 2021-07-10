import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
abstract class ChatEvent {
  const ChatEvent();
}

abstract class UserTyping extends ChatEvent {}

class UserStartedTyping extends UserTyping {
  @override
  String toString() => "UserStartedTyping()";
}

class UserStoppedTyping extends UserTyping {
  @override
  String toString() => "UserStoppedTyping()";
}

enum ChatUserEvent { left, joined }

class ChatUser extends ChatEvent {
  final String userName;
  final ChatUserEvent? userEvent;

  const ChatUser({
    required this.userName,
    this.userEvent = ChatUserEvent.joined,
  });

  factory ChatUser.fromMap(Map<String, dynamic> map, {ChatUserEvent? chatUserEvent}) {
    return ChatUser(
      userName: map['userName'],
      userEvent: chatUserEvent,
    );
  }

  @override
  String toString() => 'ChatUser(userName: $userName, userEvent: $userEvent)';
}

class Message extends ChatEvent {
  final String messageContent;
  final String? roomName;
  final String? userName;

  const Message({
    required this.messageContent,
    this.roomName,
    this.userName,
  });

  @override
  String toString() => 'Message(roomName: $roomName, content: $messageContent, userName: $userName)';

  Message copyWith({
    String? content,
    String? roomName,
    String? userName,
  }) {
    return Message(
      messageContent: content ?? this.messageContent,
      roomName: roomName ?? this.roomName,
      userName: userName ?? this.userName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageContent': messageContent,
      'roomName': roomName,
      'userName': userName,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageContent: map['messageContent'],
      roomName: map['roomName'],
      userName: map['userName'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) => Message.fromMap(json.decode(source));
}
