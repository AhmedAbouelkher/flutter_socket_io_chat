import 'dart:async';
import 'package:stream_transform/stream_transform.dart';
import 'package:flutter/material.dart';

enum TypingStatus { typing, stopped }

class AdvancedTextField extends StatefulWidget {
  final TextEditingController? controller;

  ///Called when the user `start` or `stop` typing in the textField.
  ///
  ///`enum TypingStatus { typing, stopped }`
  ///
  ///see also:
  ///- `TypingStatus` enum
  final ValueChanged<TypingStatus>? onSatusChange;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

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

  //Just for the sake of understanding the logic
  //You can remove this vaiable if you want
  // ignore: unused_field
  bool _stopped = false;

  @override
  void initState() {
    _focusNode = FocusNode();
    _streamController = StreamController.broadcast();
    var stream = _streamController.stream;
    stream.debounce(Duration(milliseconds: 800), leading: true).listen((s) {
      if (!_started) {
        _started = true;
        _stopped = false;
        widget.onSatusChange?.call(TypingStatus.typing);
      } else {
        _started = false;
        _stopped = true;
        widget.onSatusChange?.call(TypingStatus.stopped);
      }
      // print("Started: $_started, Stopped: $_stopped");
    });

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
      textCapitalization: TextCapitalization.sentences,
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
