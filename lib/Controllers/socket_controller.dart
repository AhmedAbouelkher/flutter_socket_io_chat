import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_socket_io_chat/Models/socket_models.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:provider/provider.dart';

export 'package:provider/provider.dart';

const String kLocalhost = 'http://localhost:3000';

T? stringToEnum<T>(Iterable<T?> values, value) {
  return values.firstWhere((type) => type.toString().split(".").last == value, orElse: () => null);
}

String enumToString(_enum) {
  return _enum.toString().split(".").last;
}

enum INEvent { newUserToChatRoom, updateChat, typing, stopTyping }
enum OUTEvent { subscribe, unsubscribe, newMessage, typing, stopTyping }

typedef DynamicCallback = void Function(dynamic data);

class SocketController {
  static SocketController get(BuildContext context) => context.read<SocketController>();

  Socket? _socket;
  Subscription? _subscription;

  StreamController<List<Message>>? _newMessagesController;
  List<Message>? _messages;

  Subscription? get subscription => _subscription;
  bool get connected => _socket!.connected;
  bool get disConnected => !connected;

  void init() {
    _socket ??= io(
      _localhost,
      OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    _newMessagesController ??= StreamController<List<Message>>.broadcast();
    _messages = [];
  }

  void _initListeners() {
    _connectedAssetion();
    final _socket = this._socket!;

    //TODO: impelement method
    _socket.on(enumToString(INEvent.newUserToChatRoom), (data) => null);

    _socket.on(enumToString(INEvent.updateChat), (response) {
      final _message = Message.fromJson(response);
      _addNewMessage(_message);
    });

    //TODO: impelement method
    _socket.on(enumToString(INEvent.typing), (data) => null);

    //TODO: impelement method
    _socket.on(enumToString(INEvent.stopTyping), (data) => null);
  }

  Socket connect({DynamicCallback? onConnectionError, VoidCallback? connected}) {
    assert(_socket != null);

    final _socketS = _socket!.connect();
    _socket!.onConnect((_) {
      _initListeners();
      connected?.call();
      log("Connected to Socket");
    });
    _socket!.onConnectError((data) => onConnectionError?.call(data));
    return _socketS;
  }

  Socket disconnect({VoidCallback? disconnected}) {
    final _socketS = _socket!.disconnect();
    _socket!.onDisconnect((_) {
      disconnected?.call();
      log("Disconnected");
    });
    return _socketS;
  }

  void subscribe(Subscription subscription, {VoidCallback? onSubscribe}) {
    _connectedAssetion();
    final _socket = this._socket!;
    _socket.emit(
      enumToString(OUTEvent.subscribe),
      subscription.toMap(),
    );
    this._subscription = subscription;
    onSubscribe?.call();
    log("Subscribed to ${subscription.roomName}");
  }

  void unsubscribe({VoidCallback? onUnsubscribe}) {
    _connectedAssetion();
    if (_subscription == null) return;

    final _socket = this._socket!;

    _socket.emit(
      enumToString(OUTEvent.unsubscribe),
      _subscription!.toMap(),
    );
    final _roomename = _subscription!.roomName;
    onUnsubscribe?.call();
    _subscription = null;
    log("UnSubscribed from $_roomename");
  }

  void sendMessage(Message message) {
    _connectedAssetion();
    if (_subscription == null) throw NotSubscribed();
    final _socket = this._socket!;

    _socket.emit(
      enumToString(OUTEvent.newMessage),
      message.toMap(),
    );

    _addNewMessage(message);
  }

  //TODO: impelement method
  void typing() {}

  //TODO: impelement method
  void stopTyping() {}

  void dispose() {
    _socket?.dispose();
    _newMessagesController?.close();
    _messages?.clear();

    _socket = null;
    _subscription = null;
    _newMessagesController = null;
    _messages = null;
  }

  void _connectedAssetion() {
    assert(this._socket != null);
    if (disConnected) throw NotConnected();
  }

  void _addNewMessage(Message _message) {
    _messages = _messages! + [_message];
    _newMessagesController?.sink.add(_messages!);
  }

  String get _localhost {
    final _uri = Uri.parse(kLocalhost);

    if (Platform.isIOS) return kLocalhost;

    return '${_uri.scheme}://10.0.2.2:${_uri.port}';
  }
}

class NotConnected implements Exception {}

class NotSubscribed implements Exception {}
