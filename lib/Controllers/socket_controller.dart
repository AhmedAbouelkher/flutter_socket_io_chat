import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter_socket_io_chat/Models/events.dart';
import 'package:flutter_socket_io_chat/Models/subscription_models.dart';

import 'package:socket_io_client/socket_io_client.dart';
import 'package:provider/provider.dart';

export 'package:flutter_socket_io_chat/Models/events.dart';
export 'package:provider/provider.dart';

const String kLocalhost = 'http://localhost:3000';

///Converts `enum` to `String`
String enumToString(_enum) {
  return _enum.toString().split(".").last;
}

///Error indicates that the user didn't connect to the socket
class NotConnected implements Exception {}

///Error indicates that the user didn't subscribe to a room
class NotSubscribed implements Exception {}

/// Incoming Events
///
/// see also:
/// - enum `OUTEvent`
/// - `Node.js` Server code.
enum INEvent {
  newUserToChatRoom,
  userLeftChatRoom,
  updateChat,
  typing,
  stopTyping,
}

/// Outgoing Events
///
/// see also:
/// - enum `INEvent`
/// - `Node.js` Server code.
enum OUTEvent {
  subscribe,
  unsubscribe,
  newMessage,
  typing,
  stopTyping,
}

typedef DynamicCallback = void Function(dynamic data);

class SocketController {
  ///Get a provider instatnce of the class
  ///
  ///if you want to call this method in `initState` method, remember to call after the first frame.
  ///
  ///example:
  ///```
  /// WidgetsBinding.instance?.addPostFrameCallback((_) {
  ///     SocketController.get(context)
  ///       ..init()
  ///       ..connect();
  /// });
  ///```
  static SocketController get(BuildContext context) => context.read<SocketController>();

  Socket? _socket;
  Subscription? _subscription;

  StreamController<List<ChatEvent>>? _newMessagesController;
  List<ChatEvent>? _events;

  ///Current user room subscription
  Subscription? get subscription => _subscription;

  ///`Boolean` represents the state of the socket if it is currently connected.
  bool get connected => _socket!.connected;

  ///`Boolean` represents the state of the socket if it is currently diconnected form the server.
  bool get disConnected => !connected;

  ///Returns a stream with the chat messages.
  Stream<List<ChatEvent>>? get watchEvents => _newMessagesController?.stream.asBroadcastStream();

  /// Initializes the controller and its streams
  ///
  /// see also:
  /// - `connect()`
  void init({String? url}) {
    _socket ??= io(
      url ?? _localhost,
      OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    _newMessagesController ??= StreamController<List<ChatEvent>>.broadcast();
    _events = [];
  }

  ///initializes the events listeners and sends the events to the stream controller sink
  void _initListeners() {
    _connectedAssetion();
    final _socket = this._socket!;

    _socket.on(enumToString(INEvent.newUserToChatRoom), (data) {
      final _user = ChatUser.fromMap(data, chatUserEvent: ChatUserEvent.joined);
      _newUserEvent(_user);
    });

    _socket.on(enumToString(INEvent.userLeftChatRoom), (data) {
      final _user = ChatUser.fromMap(data, chatUserEvent: ChatUserEvent.left);
      _newUserEvent(_user);
    });

    _socket.on(enumToString(INEvent.updateChat), (response) {
      final _message = Message.fromJson(response);
      _addNewMessage(_message);
    });

    _socket.on(enumToString(INEvent.typing), (_) {
      _addTypingEvent(UserStartedTyping());
    });

    _socket.on(enumToString(INEvent.stopTyping), (_) {
      _addTypingEvent(UserStoppedTyping());
    });
  }

  ///Connects the device to the socket and initializes all the event listeners
  ///
  /// @Params:
  /// - `onConnectionError`: socket error callback method.
  /// - `connected`: socket conection success callback method.
  Socket connect({DynamicCallback? onConnectionError, VoidCallback? connected}) {
    assert(_socket != null, "Did you forget to call `init()` first?");

    final _socketS = _socket!.connect();

    _socket!.onConnect((_) {
      _initListeners();
      connected?.call();
      log("Connected to Socket");
    });

    _socket!.onConnectError((data) => onConnectionError?.call(data));
    return _socketS;
  }

  ///Disconnects the device from the socket.
  ///
  /// @Params:
  /// - `disconnected`: socket disconection success callback method.
  Socket disconnect({VoidCallback? disconnected}) {
    final _socketS = _socket!.disconnect();
    _socket!.onDisconnect((_) {
      disconnected?.call();
      log("Disconnected");
    });
    return _socketS;
  }

  ///Subscribe to a room using `subscription`
  ///
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

  ///unsubscribe from a room
  ///
  void unsubscribe({VoidCallback? onUnsubscribe}) {
    _connectedAssetion();
    if (_subscription == null) return;

    final _socket = this._socket!;

    _socket
      ..emit(
        enumToString(OUTEvent.stopTyping),
        _subscription!.roomName,
      )
      ..emit(
        enumToString(OUTEvent.unsubscribe),
        _subscription!.toMap(),
      );

    final _roomename = _subscription!.roomName;

    onUnsubscribe?.call();
    _subscription = null;
    _events?.clear();
    log("UnSubscribed from $_roomename");
  }

  ///Sends a message to the users in the same room.
  ///
  void sendMessage(Message message) {
    _connectedAssetion();
    if (_subscription == null) throw NotSubscribed();
    final _socket = this._socket!;

    final _message = message.copyWith(
      userName: subscription!.userName,
      roomName: subscription!.roomName,
    );

    //Stop typing then send new message.
    _socket
      ..emit(
        enumToString(OUTEvent.stopTyping),
        _subscription!.roomName,
      )
      ..emit(
        enumToString(OUTEvent.newMessage),
        _message.toMap(),
      );

    _addNewMessage(_message);
  }

  ///Sends to the room that the current user is typing.
  void typing() {
    _connectedAssetion();
    if (_subscription == null) throw NotSubscribed();
    final _socket = this._socket!;
    _socket.emit(enumToString(OUTEvent.typing), _subscription!.roomName);
  }

  //Informs the room members that tha current user has stopped typing.
  void stopTyping() {
    _connectedAssetion();
    if (_subscription == null) throw NotSubscribed();
    final _socket = this._socket!;
    _socket.emit(enumToString(OUTEvent.stopTyping), _subscription!.roomName);
  }

  ///Disposes all the objects which have been initialized and resests the whole controller.
  void dispose() {
    _socket?.dispose();
    _newMessagesController?.close();
    _events?.clear();
    unsubscribe();

    _socket = null;
    _subscription = null;
    _newMessagesController = null;
    _events = null;
  }

  void _connectedAssetion() {
    assert(this._socket != null, "Did you forget to call `init()` first?");
    if (disConnected) throw NotConnected();
  }

  void _addNewMessage(Message message) => _addEvent(message);

  void _newUserEvent(ChatUser user) => _addEvent(user);

  void _addTypingEvent(UserTyping event) {
    _events!.removeWhere((e) => e is UserTyping);
    _events = <ChatEvent>[event, ..._events!];
    _newMessagesController?.sink.add(_events!);
  }

  ///Add new event to the steam sink
  ///
  ///see also:
  /// * `watchEvents` getter
  void _addEvent(event) {
    _events = <ChatEvent>[event, ..._events!];
    _newMessagesController?.sink.add(_events!);
  }

  String get _localhost {
    final _uri = Uri.parse(kLocalhost);

    if (Platform.isIOS) return kLocalhost;

    //Android local url
    return '${_uri.scheme}://10.0.2.2:${_uri.port}';
  }
}
