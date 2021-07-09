import 'package:flutter/material.dart';
import 'package:flutter_socket_io_chat/Controllers/socket_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final SocketController? _socketController;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _socketController ??= SocketController.get(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _socketController!.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(_socketController!.subscription?.roomName ?? "-"),
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
                  top: null,
                  bottom: 20,
                  child: TextField(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
