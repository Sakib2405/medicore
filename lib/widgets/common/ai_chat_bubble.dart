import 'package:flutter/material.dart';

class AiChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const AiChatBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        margin: const EdgeInsets.symmetric(vertical: 4).copyWith(
          left: isUser ? 80 : 8,
          right: isUser ? 8 : 80,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.primaryColor
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          text,
          style: TextStyle(
            color:
                isUser ? Colors.white : theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
