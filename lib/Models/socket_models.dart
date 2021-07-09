import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class Message {
  final String roomName;
  final String content;
  final String? userName;

  const Message({
    required this.roomName,
    required this.content,
    this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomName': roomName,
      'content': content,
      'userName': userName,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      roomName: map['roomName'],
      content: map['content'],
      userName: map['userName'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) => Message.fromMap(json.decode(source));

  @override
  String toString() => 'Message(roomName: $roomName, content: $content, userName: $userName)';
}

@immutable
class Subscription {
  final String roomName;
  final String userName;
  Subscription({
    required this.roomName,
    required this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomName': roomName,
      'userName': userName,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      roomName: map['roomName'],
      userName: map['userName'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Subscription.fromJson(String source) => Subscription.fromMap(json.decode(source));

  @override
  String toString() => 'Subscription(roomName: $roomName, userName: $userName)';
}
