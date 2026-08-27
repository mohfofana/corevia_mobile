import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';

import '../../pillbox/presentation/providers/pillbox_provider.dart';
import '../data/ai_chat_service.dart';
import '../domain/chat_message.dart';
import 'widgets/chat_bubble.dart';

class AiChatModal extends StatefulWidget {
  const AiChatModal({super.key});

  @override
  State<AiChatModal> createState() => _AiChatModalState();
}

class _AiChatModalState extends State<AiChatModal> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiChatService _chatService = AiChatService();

  bool _isStreaming = false;
  CancelToken? _activeCancelToken;

  @override
  void dispose() {
    _activeCancelToken?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isStreaming) return;

    _inputController.clear();

    final userMessage = ChatMessage(role: ChatRole.user, content: text);

    setState(() {
      _messages.add(userMessage);
    });

    _streamResponse();
  }

  /// Starts a streaming request to /chat with the current messages.
  void _streamResponse() {
    final assistantMessage = ChatMessage(role: ChatRole.assistant, content: '');

    setState(() {
      _messages.add(assistantMessage);
      _isStreaming = true;
    });

    _scrollToBottom();

    _activeCancelToken = _chatService.streamChat(
      messages: _messages.where((m) => !m.isError && (m.content.isNotEmpty || m.toolCalls.isNotEmpty)).toList(),
      onDelta: (delta) {
        if (!mounted) return;
        setState(() {
          assistantMessage.content += delta;
        });
        _scrollToBottom();
      },
      onToolCall: (toolCall) {
        if (!mounted) return;
        setState(() {
          assistantMessage.toolCalls.add(toolCall);
        });
        _scrollToBottom();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          if (assistantMessage.content.isEmpty && assistantMessage.toolCalls.isEmpty) {
            _messages.remove(assistantMessage);
            _messages.add(ChatMessage(
              role: ChatRole.assistant,
              content: error,
              isError: true,
            ));
          }
        });
        _scrollToBottom();
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isStreaming = false;
          _activeCancelToken = null;
          if (assistantMessage.content.isEmpty &&
              assistantMessage.toolCalls.isEmpty &&
              _messages.contains(assistantMessage)) {
            _messages.remove(assistantMessage);
          }
        });
      },
    );
  }

  void _approveToolCall(ToolCallInfo toolCall) {
    setState(() {
      toolCall.state = ToolCallState.approved;
    });

    _refreshProviders(toolCall.toolName);
    _resendIfAllResponded();
  }

  void _rejectToolCall(ToolCallInfo toolCall) {
    setState(() {
      toolCall.state = ToolCallState.rejected;
    });

    _resendIfAllResponded();
  }

  void _approveAllToolCalls() {
    setState(() {
      for (final msg in _messages) {
        for (final tc in msg.toolCalls) {
          if (tc.state == ToolCallState.pending) {
            tc.state = ToolCallState.approved;
            _refreshProviders(tc.toolName);
          }
        }
      }
    });
    _resendIfAllResponded();
  }

  void _rejectAllToolCalls() {
    setState(() {
      for (final msg in _messages) {
        for (final tc in msg.toolCalls) {
          if (tc.state == ToolCallState.pending) {
            tc.state = ToolCallState.rejected;
          }
        }
      }
    });
    _resendIfAllResponded();
  }

  /// Only re-send when ALL pending tool calls have been responded to.
  void _resendIfAllResponded() {
    final hasPending = _messages.any((m) => m.hasPendingToolCalls);
    if (!hasPending) {
      _streamResponse();
    }
  }

  void _refreshProviders(String toolName) {
    final providerType = ToolCallInfo.refreshProviders[toolName];
    if (providerType == null) return;

    switch (providerType) {
      case 'pillbox':
        try {
          final pillbox = context.read<PillboxProvider>();
          pillbox.loadTodayIntakes();
          pillbox.loadMedications();
        } catch (_) {}
        break;
    }
  }

  void _stopStreaming() {
    _activeCancelToken?.cancel();
    setState(() {
      _isStreaming = false;
      _activeCancelToken = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _buildHeader(),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(child: _buildMessageList()),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFF34C759),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.l10n.docAiAssistant,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                Text(
                  _isStreaming ? context.l10n.writingStatus : context.l10n.online,
                  style: TextStyle(
                    fontSize: 13,
                    color: _isStreaming ? const Color(0xFF34C759) : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF1D1D1F)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF5F5F7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              context.l10n.askDocAi,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final pendingCount = _messages.fold<int>(
      0, (sum, m) => sum + m.toolCalls.where((tc) => tc.state == ToolCallState.pending).length,
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) => ChatBubble(
              message: _messages[index],
              onApprove: _isStreaming ? null : _approveToolCall,
              onReject: _isStreaming ? null : _rejectToolCall,
            ),
          ),
        ),
        if (pendingCount > 1 && !_isStreaming)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _approveAllToolCalls,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${context.l10n.approveAll} ($pendingCount)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _rejectAllToolCalls,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          context.l10n.rejectAll,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _inputController,
                  enabled: !_isStreaming,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: context.l10n.writeMessage,
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1D1D1F)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isStreaming ? _stopStreaming : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isStreaming ? const Color(0xFFEF4444) : const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  _isStreaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the AI chat as a bottom sheet modal.
/// Uses rootNavigator to escape the ShellRoute's BottomNavBar overlay.
void showAiChatModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (modalContext) => ChangeNotifierProvider.value(
      value: context.read<PillboxProvider>(),
      child: const AiChatModal(),
    ),
  );
}
