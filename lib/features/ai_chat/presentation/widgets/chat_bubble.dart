import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';

import '../../domain/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(ToolCallInfo)? onApprove;
  final void Function(ToolCallInfo)? onReject;

  const ChatBubble({
    super.key,
    required this.message,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final isError = message.isError;

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Text bubble (if content exists or is loading)
        if (message.content.isNotEmpty || (message.toolCalls.isEmpty && !isError))
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              margin: EdgeInsets.only(
                left: isUser ? 48 : 0,
                right: isUser ? 0 : 48,
                bottom: 8,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError
                    ? const Color(0xFFFEE2E2)
                    : isUser
                        ? const Color(0xFF34C759)
                        : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  : _AssistantContent(message: message, isError: isError),
            ),
          ),

        // Tool call cards
        for (final tc in message.toolCalls)
          _ToolCallCard(
            toolCall: tc,
            onApprove: onApprove != null ? () => onApprove!(tc) : null,
            onReject: onReject != null ? () => onReject!(tc) : null,
          ),
      ],
    );
  }
}

class _AssistantContent extends StatelessWidget {
  final ChatMessage message;
  final bool isError;

  const _AssistantContent({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    if (message.content.isEmpty) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF34C759),
        ),
      );
    }

    final textColor =
        isError ? const Color(0xFFDC2626) : const Color(0xFF1D1D1F);

    return MarkdownBody(
      data: message.content,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 15, height: 1.5, color: textColor),
        strong: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
        em: TextStyle(
            fontSize: 15, fontStyle: FontStyle.italic, color: textColor),
        code: TextStyle(
          fontSize: 13,
          color: textColor,
          backgroundColor: Colors.black.withValues(alpha: 0.05),
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF1D1D1F),
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        listBullet: TextStyle(fontSize: 15, color: textColor),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey.shade400, width: 3),
          ),
        ),
        blockquotePadding:
            const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      ),
    );
  }
}

class _ToolCallCard extends StatelessWidget {
  final ToolCallInfo toolCall;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ToolCallCard({
    required this.toolCall,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = toolCall.state == ToolCallState.pending;
    final isApproved = toolCall.state == ToolCallState.approved;
    final isRejected = toolCall.state == ToolCallState.rejected;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.only(right: 48, bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPending
              ? const Color(0xFFFFF7ED)
              : isApproved
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPending
                ? const Color(0xFFFED7AA)
                : isApproved
                    ? const Color(0xFFBBF7D0)
                    : const Color(0xFFFECACA),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPending
                      ? Icons.pending_actions_rounded
                      : isApproved
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                  size: 18,
                  color: isPending
                      ? const Color(0xFFEA580C)
                      : isApproved
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    toolCall.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: context.l10n.approve,
                      color: const Color(0xFF34C759),
                      onTap: onApprove,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: context.l10n.reject,
                      color: const Color(0xFFEF4444),
                      onTap: onReject,
                    ),
                  ),
                ],
              ),
            ],
            if (isApproved)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  context.l10n.approved,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A)),
                ),
              ),
            if (isRejected)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  context.l10n.rejected,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
