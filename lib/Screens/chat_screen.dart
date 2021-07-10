import 'dart:async';
import 'package:stream_transform/stream_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_socket_io_chat/Controllers/socket_controller.dart';
import 'package:flutter_socket_io_chat/Widget/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  SocketController? _socketController;
  late final TextEditingController _textEditingController;

  bool _hasText = false;

  @override
  void initState() {
    _textEditingController = TextEditingController();

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _socketController = SocketController.get(context);
      _textEditingController.addListener(() {
        final _text = _textEditingController.text.trim();
        if (_text.isEmpty) {
          _socketController!.stopTyping();
          _hasText = false;
        } else {
          if (_hasText) return;
          _socketController!.typing();
          _hasText = true;
        }
      });

      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _socketController!.unsubscribe();
    _textEditingController.dispose();

    super.dispose();
  }

  void _sendMessage() {
    if (_textEditingController.text.isEmpty) return;
    final _message = Message(messageContent: _textEditingController.text);
    _socketController?.sendMessage(_message);
    _textEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(_socketController?.subscription?.roomName ?? "-"),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  _socketController!.unsubscribe();
                  Navigator.pop(context);
                },
              )
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: StreamBuilder<List<ChatEvent>>(
                      stream: _socketController?.watchEvents,
                      initialData: [],
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Center(child: CircularProgressIndicator.adaptive());
                        final _events = snapshot.data!;
                        if (_events.isEmpty) return Center(child: Text("Start sending..."));
                        return ListView.separated(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0).add(
                            const EdgeInsets.only(bottom: 70.0),
                          ),
                          itemCount: _events.length,
                          separatorBuilder: (context, index) => SizedBox(height: 5.0),
                          itemBuilder: (context, index) {
                            final _event = _events[index];

                            if (_event is Message) {
                              return TextBubble(
                                message: _event,
                                type: _event.userName == _socketController!.subscription!.userName
                                    ? BubbleType.sendBubble
                                    : BubbleType.receiverBubble,
                              );
                            } else if (_event is ChatUser) {
                              if (_event.userEvent == ChatUserEvent.left) {
                                return Center(child: Text("${_event.userName} left"));
                              }
                              return Center(child: Text("${_event.userName} has joined"));
                            } else if (_event is UserStartedTyping) {
                              return UserTypingBubble();
                            }
                            return SizedBox();
                          },
                        );
                      }),
                ),
                Positioned.fill(
                  top: null,
                  bottom: 0,
                  child: Container(
                    color: Colors.white,
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Expanded(
                          child: AdvancedTextField(
                            hintText: "Type your message...",
                            controller: _textEditingController,
                            onSubmitted: (value) {
                              _sendMessage();
                            },
                            onSatusChange: (status) {
                              if (status == TypingStatus.stopped) {
                                _socketController!.stopTyping();
                                return;
                              }
                              _socketController!.typing();
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          onPressed: () => _sendMessage(),
                          icon: Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum TypingStatus { typing, stopped }

class AdvancedTextField extends StatefulWidget {
  final ValueChanged<TypingStatus>? onSatusChange;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;

  final String? hintText;

  const AdvancedTextField({
    Key? key,
    this.onSatusChange,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.hintText,
  }) : super(key: key);
  @override
  _AdvancedTextFieldState createState() => _AdvancedTextFieldState();
}

class _AdvancedTextFieldState extends State<AdvancedTextField> {
  late final StreamController<String> _streamController;
  late final FocusNode _focusNode;
  bool _started = false;
  // ignore: unused_field
  bool _stopped = false;

  @override
  void initState() {
    _focusNode = FocusNode();
    _streamController = StreamController.broadcast();
    var stream = _streamController.stream;
    // stream.debounce(Duration(milliseconds: 800), leading: true).listen((s) {
    //   if (!_started) {
    //     _started = true;
    //     _stopped = false;
    //     widget.onSatusChange?.call(TypingStatus.typing);
    //   } else {
    //     _started = false;
    //     _stopped = true;
    //     widget.onSatusChange?.call(TypingStatus.stopped);
    //   }
    //   print("Started: $_started, Stopped: $_stopped");
    // });

    super.initState();
  }

  @override
  void dispose() {
    _streamController.close();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focusNode,
      onChanged: (value) {
        widget.onChanged?.call(value);
        _streamController.sink.add(value);
      },
      onSubmitted: (value) {
        widget.onSubmitted?.call(value);
        _focusNode.requestFocus();
      },
      controller: widget.controller,
      decoration: InputDecoration(hintText: widget.hintText),
    );
  }
}
