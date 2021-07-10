import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart' as urlLauncher;

import 'package:flutter_socket_io_chat/Models/events.dart';

enum BubbleType { sendBubble, receiverBubble }

class TextBubble extends StatelessWidget {
  final Message message;
  final BubbleType type;
  final BorderRadiusGeometry? borderRadius;

  const TextBubble({
    Key? key,
    required this.message,
    required this.type,
    this.borderRadius,
  }) : super(key: key);

  Color get _messageColor {
    return type == BubbleType.sendBubble ? Colors.blue : Colors.green;
  }

  ui.TextDirection get _messageDirection {
    return type == BubbleType.sendBubble ? ui.TextDirection.rtl : ui.TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;
    return Row(
      textDirection: _messageDirection,
      children: [
        InkWell(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: message.messageContent.trim()));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Copied to Clipboard")));
          },
          child: Container(
            constraints: BoxConstraints(maxWidth: _size.width * 0.6, minWidth: 0),
            margin: EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(15),
              color: _messageColor,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: _buildParsedText(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParsedText(BuildContext context) {
    final _arabicRegex = RegExp(r'^[\u0600-\u06FF]');
    final isArabicText = _arabicRegex.hasMatch(message.messageContent);
    return ParsedText(
      alignment: TextAlign.end,
      text: message.messageContent.trim(),
      textDirection: isArabicText ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      parse: <MatchText>[
        MatchText(
          type: ParsedType.EMAIL,
          style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
          onTap: (email) {
            urlLauncher.launch("mailto:" + email);
          },
        ),
        MatchText(
          type: ParsedType.URL,
          style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
          onTap: (url) async {
            var _canLaunch = await urlLauncher.canLaunch(url);

            if (_canLaunch) {
              urlLauncher.launch(url, statusBarBrightness: Brightness.light);
            }
          },
        ),
        MatchText(
          type: ParsedType.PHONE,
          style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
          onTap: (phoneNumber) async {
            var _canLaunch = await urlLauncher.canLaunch("tel://$phoneNumber");

            if (_canLaunch) {
              urlLauncher.launch("tel://$phoneNumber", statusBarBrightness: Brightness.light);
            }
          },
        ),
      ],
      style: TextStyle(color: Colors.white),
    );
  }
}

class UserTypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: 50, minWidth: 0, maxHeight: 40),
          margin: EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.green,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: LoadingIndicator(
              indicatorType: Indicator.ballPulse,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
