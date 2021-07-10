import 'dart:convert';

import 'package:flutter/foundation.dart';

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
