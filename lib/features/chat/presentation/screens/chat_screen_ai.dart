import 'dart:async';

import 'package:corevia_mobile/features/ai_chat/data/rag_chat_storage.dart';
import 'package:corevia_mobile/features/ai_chat/data/rag_socket_chat_service.dart';
import 'package:corevia_mobile/features/ai_chat/data/rag_socket_config.dart';
import 'package:corevia_mobile/features/ai_chat/domain/chat_message.dart' as rag;
import 'package:corevia_mobile/features/account/presentation/providers/user_provider.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';
import 'package:corevia_mobile/widgets/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

// Modèle pour les IAs spécialisées
class AIDoctor {
  final String id;
  final String Function(AppLocalizations l10n) nameBuilder;
  final String Function(AppLocalizations l10n) specialtyBuilder;
  final Color primaryColor;
  final Color secondaryColor;
  final bool supported;
  final String? ragAgentId;

  const AIDoctor({
    required this.id,
    required this.nameBuilder,
    required this.specialtyBuilder,
    required this.primaryColor,
    required this.secondaryColor,
    required this.supported,
    required this.ragAgentId,
  });

  String name(AppLocalizations l10n) => nameBuilder(l10n);
  String specialty(AppLocalizations l10n) => specialtyBuilder(l10n);
}

// Liste des IAs disponibles
final List<AIDoctor> availableAIs = [
  AIDoctor(
    id: 'doc_locke',
    nameBuilder: (l10n) => l10n.generalPractitioner,
    specialtyBuilder: (l10n) => l10n.generalMedicine,
    primaryColor: Color(0xFF34C759),
    secondaryColor: Color(0xFF5DF394),
    supported: true,
    ragAgentId: 'medecin_generaliste',
  ),
  AIDoctor(
    id: 'dr_dermato',
    nameBuilder: (l10n) => l10n.dermatologist,
    specialtyBuilder: (l10n) => l10n.dermatology,
    primaryColor: Color(0xFFFF9500),
    secondaryColor: Color(0xFFFFB340),
    supported: true,
    ragAgentId: 'dermatologue',
  ),
  AIDoctor(
    id: 'dr_nutrition',
    nameBuilder: (l10n) => l10n.nutritionist,
    specialtyBuilder: (l10n) => l10n.nutrition,
    primaryColor: Color(0xFF0EA5E9),
    secondaryColor: Color(0xFF38BDF8),
    supported: true,
    ragAgentId: 'nutritionniste',
  ),
  AIDoctor(
    id: 'dr_psy',
    nameBuilder: (l10n) => l10n.psychologist,
    specialtyBuilder: (l10n) => l10n.mentalHealth,
    primaryColor: Color(0xFF8B5CF6),
    secondaryColor: Color(0xFFA78BFA),
    supported: true,
    ragAgentId: 'psychologue',
  ),
];

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? aiDoctorId;
  
  const ChatScreen({
    super.key, 
    required this.conversationId,
    this.aiDoctorId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late AIDoctor _currentAI;
  late chat_core.User _assistant;
  final chat_core.User _currentUser = const chat_core.User(
    id: 'user',
    name: 'Patient',
  );
  chat_core.InMemoryChatController? _chatController;
  bool _isTyping = false;
  final RagChatStorage _ragStorage = RagChatStorage();
  late final RagSocketChatService _ragSocket;
  String _ragAgentId = 'medecin_generaliste';
  String? _ragUserId;
  bool _isConnected = false;
  bool _isStreaming = false;
  chat_core.TextMessage? _assistantMessage;
  String _assistantBuffer = '';
  bool _warnedUnsupportedAi = false;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  late AnimationController _typingAnimationController;

  String _patientName(BuildContext context) {
    final userName = context.read<UserProvider>().user?.name.trim();
    if (userName != null && userName.isNotEmpty) {
      return userName;
    }
    return context.l10n.patient;
  }

  @override
  void initState() {
    super.initState();
    
    // Initialiser l'IA actuelle
    final requestedId = widget.aiDoctorId ?? 'doc_locke';
    final requestedAI = availableAIs.firstWhere(
      (ai) => ai.id == requestedId,
      orElse: () => availableAIs[0],
    );
    final fallbackAI = availableAIs.firstWhere((ai) => ai.id == 'doc_locke');
    _currentAI = requestedAI.supported ? requestedAI : fallbackAI;
    
    _assistant = chat_core.User(
      id: _currentAI.id,
      name: _currentAI.id,
    );
    
    _ragAgentId = _currentAI.ragAgentId ?? 'medecin_generaliste';
    _ragSocket = RagSocketChatService(url: RagSocketConfig.resolveUrl());

    _initChatController();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _bootstrapRagChat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!requestedAI.supported && !_warnedUnsupportedAi) {
        _warnedUnsupportedAi = true;
        _showSoonSnackBar();
      }
    });
  }
  
  void _initChatController({List<chat_core.Message>? initialMessages}) {
    _chatController?.dispose();
    _chatController = chat_core.InMemoryChatController(messages: initialMessages);
  }
    
  Future<void> _bootstrapRagChat() async {
    if (!_currentAI.supported || _currentAI.ragAgentId == null) return;

    final agentId = _currentAI.ragAgentId!;
    final userId = await _ragStorage.getOrCreateUserId();
    final history = await _ragStorage.loadUserHistory(agentId);

    final initial = _toCoreUserMessages(history);
    if (!mounted) return;

    setState(() {
      _ragAgentId = agentId;
      _ragUserId = userId;
      _initChatController(initialMessages: initial);
    });

    _ragSocket.connect(onConnectionChanged: (connected) {
      if (!mounted) return;
      setState(() {
        _isConnected = connected;
      });
    });

    if (initial.isEmpty && mounted) {
        setState(() {
          _addSystemMessage(
            context.l10n.aiDoctorGreeting(
              _patientName(context),
              _currentAI.name(context.l10n),
              _currentAI.specialty(context.l10n),
            ),
          );
      });
    }
  }

  List<chat_core.Message> _toCoreUserMessages(List<rag.ChatMessage> history) {
    final messages = <chat_core.Message>[];
    for (var i = 0; i < history.length; i++) {
      final item = history[i];
      final createdAt = item.timestamp;
      messages.add(chat_core.Message.text(
        id: 'rag_u_${createdAt.millisecondsSinceEpoch}_$i',
        authorId: _currentUser.id,
        createdAt: createdAt,
        text: item.content,
      ));
    }

    messages.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return messages;
  }

  void _addSystemMessage(String text) {
    if (_chatController != null) {
      final message = _buildTextMessage(author: _assistant, text: text);
      _chatController?.insertMessage(message, index: 0);
    }
  }

  void _showAISelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // En-tête
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6C63FF), size: 28),
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.chooseSpecialist,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 24, color: Colors.grey),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Liste des IAs
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableAIs.length,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      itemBuilder: (context, index) {
                        final ai = availableAIs[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _currentAI.id == ai.id 
                                ? ai.primaryColor.withValues(alpha:0.1) 
                                : Colors.grey.withValues(alpha:0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: _currentAI.id == ai.id
                                ? Border.all(color: ai.primaryColor, width: 1.5)
                                : null,
                            boxShadow: _currentAI.id == ai.id ? [
                              BoxShadow(
                                color: ai.primaryColor.withValues(alpha:0.1),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ] : null,
                          ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  // Fermer la boîte de dialogue immédiatement
                                  Navigator.of(context).pop();

                                  if (!ai.supported) {
                                    _showSoonSnackBar();
                                    return;
                                  }

                                  if (ai.id == _currentAI.id) return;

                                  _stopStreaming();
                                  setState(() {
                                    _currentAI = ai;
                                    _assistant = chat_core.User(
                                      id: _currentAI.id,
                                      name: _currentAI.id,
                                    );
                                    _ragAgentId = _currentAI.ragAgentId ?? 'medecin_generaliste';
                                    _isTyping = false;
                                  });

                                  await _bootstrapRagChat();
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [ai.secondaryColor, ai.primaryColor],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: ai.primaryColor.withValues(alpha:0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome_rounded, 
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Texte
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ai.name(context.l10n),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1D1D1F),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ai.supported
                                                ? ai.specialty(context.l10n)
                                                : '${ai.specialty(context.l10n)} • ${context.l10n.soonAvailable}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Indicateur de sélection
                                    if (_currentAI.id == ai.id)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: ai.primaryColor.withValues(alpha:0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_circle_rounded,
                                          color: ai.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                    if (_currentAI.id != ai.id && !ai.supported)
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        color: Colors.grey.shade500,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Bouton de fermeture
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6C63FF),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                        ),
                      ),
                      child: Text(
                        context.l10n.close,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header du drawer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_currentAI.primaryColor, _currentAI.secondaryColor],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _patientName(context),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.patient,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bouton nouvelle conversation
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context); // Fermer le drawer
                  _showAISelectionDialog();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_currentAI.primaryColor, _currentAI.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _currentAI.primaryColor.withValues(alpha:0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        context.l10n.chooseSpecialty,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Section IAs disponibles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    context.l10n.specialties,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.withValues(alpha:0.2),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // Liste des IAs
            ...availableAIs.map((ai) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ai.secondaryColor, ai.primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                ai.name(context.l10n),
                style: TextStyle(
                  fontWeight: ai.id == _currentAI.id ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                  color: !ai.supported
                      ? Colors.grey.shade500
                      : ai.id == _currentAI.id
                          ? ai.primaryColor
                          : const Color(0xFF1D1D1F),
                ),
              ),
              subtitle: Text(
                ai.supported
                    ? ai.specialty(context.l10n)
                    : '${ai.specialty(context.l10n)} • ${context.l10n.soonAvailable}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.withValues(alpha:0.2),
                ),
              ),
              trailing: ai.id == _currentAI.id
                  ? Icon(Icons.check_circle, color: ai.primaryColor, size: 20)
                  : ai.supported
                      ? null
                      : Icon(Icons.lock_outline_rounded, color: Colors.grey.shade500, size: 18),
              onTap: () {
                Navigator.pop(context);
                if (!ai.supported) {
                  _showSoonSnackBar();
                  return;
                }
                if (ai.id != _currentAI.id) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: 'new',
                        aiDoctorId: ai.id,
                      ),
                    ),
                  );
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final supported = _currentAI.supported && _currentAI.ragAgentId != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                enabled: supported && !_isStreaming,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(
                  color: Color(0xFF1D1D1F), 
                  fontSize: 15,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (supported && !_isStreaming) ? (_) => _sendCurrentMessage() : null,
                decoration: InputDecoration(
                  hintText: supported ? context.l10n.writeMessage : context.l10n.soonAvailable,
                  hintStyle: TextStyle(
                    color: Colors.grey.withValues(alpha:0.2), 
                    fontSize: 15,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: _isStreaming ? const Color(0xFFEF4444) : null,
              gradient: _isStreaming
                  ? null
                  : LinearGradient(
                      colors: [_currentAI.secondaryColor, _currentAI.primaryColor],
                    ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (_isStreaming ? const Color(0xFFEF4444) : _currentAI.primaryColor).withValues(alpha:0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isStreaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _isStreaming ? _stopStreaming : (supported ? _sendCurrentMessage : _showSoonSnackBar),
            ),
          ),
        ],
      ),
    );
  }

  void _sendCurrentMessage() {
    if (_isStreaming) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Effacer le champ de texte et donner le focus
    _messageController.clear();
    _messageFocusNode.requestFocus();

    unawaited(_sendRagQuery(text));
  }

  Future<void> _sendRagQuery(String text) async {
    if (!_currentAI.supported || _currentAI.ragAgentId == null) {
      _showSoonSnackBar();
      return;
    }

    final controller = _chatController;
    if (controller == null) return;

    final now = DateTime.now();
    final userMessage = chat_core.Message.text(
      id: 'u_${now.microsecondsSinceEpoch}',
      authorId: _currentUser.id,
      createdAt: now,
      text: text,
    );

    if (!mounted) return;
    setState(() {
      _isStreaming = true;
      _isTyping = true;
      _assistantMessage = null;
      _assistantBuffer = '';
      unawaited(controller.insertMessage(userMessage, index: 0));
    });

    try {
      await _ragStorage.appendUserMessage(
        _ragAgentId,
        rag.ChatMessage(role: rag.ChatRole.user, content: text, timestamp: now),
      );
    } catch (_) {}

    _ragUserId ??= await _ragStorage.getOrCreateUserId();
    final userId = _ragUserId!;

    await _ragSocket.sendQuery(
      agentId: _ragAgentId,
      query: text,
      userId: userId,
      onDelta: (delta) {
        if (!mounted) return;
        setState(() {
          if (_assistantMessage == null) {
            _assistantBuffer = delta;
            final msg = chat_core.Message.text(
              id: 'a_${DateTime.now().microsecondsSinceEpoch}',
              authorId: _assistant.id,
              createdAt: DateTime.now(),
              text: _assistantBuffer,
            ) as chat_core.TextMessage;
            _assistantMessage = msg;
            _isTyping = false;
            unawaited(controller.insertMessage(msg, index: 0));
          } else {
            _assistantBuffer += delta;
            final updated = _assistantMessage!.copyWith(
              text: _assistantBuffer,
              updatedAt: DateTime.now(),
            );
            unawaited(controller.updateMessage(_assistantMessage!, updated));
            _assistantMessage = updated;
          }
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isStreaming = false;
          _isTyping = false;
          _assistantMessage = null;
          _assistantBuffer = '';
        });
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _isStreaming = false;
          _isTyping = false;

          if (_assistantMessage == null) {
            final err = chat_core.Message.text(
              id: 'err_${DateTime.now().microsecondsSinceEpoch}',
              authorId: _assistant.id,
              createdAt: DateTime.now(),
              text: message,
            );
            unawaited(controller.insertMessage(err, index: 0));
          } else {
            final updated = _assistantMessage!.copyWith(
              text: '${_assistantBuffer}\n\n$message',
              updatedAt: DateTime.now(),
            );
            unawaited(controller.updateMessage(_assistantMessage!, updated));
            _assistantMessage = updated;
          }
        });
      },
    );
  }

  void _stopStreaming() {
    _ragSocket.disconnect();
    setState(() {
      _isStreaming = false;
      _isTyping = false;
      _assistantMessage = null;
      _assistantBuffer = '';
    });
  }

  void _showSoonSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.soonAvailable)),
    );
  }

  Future<void> _clearHistory() async {
    if (!_currentAI.supported || _currentAI.ragAgentId == null) return;

    _stopStreaming();

    try {
      await _ragStorage.clearUserHistory(_ragAgentId);
      await _ragStorage.resetUserId();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _ragUserId = null;
      _assistantMessage = null;
      _assistantBuffer = '';
      _initChatController(initialMessages: []);
    });

    if (mounted) {
      setState(() {
        _addSystemMessage(
          context.l10n.aiDoctorGreeting(
            _patientName(context),
            _currentAI.name(context.l10n),
            _currentAI.specialty(context.l10n),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _ragSocket.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _typingAnimationController.dispose();
    _chatController?.dispose();
    super.dispose();
  }

  chat_core.Message _buildTextMessage({
    required chat_core.User author,
    required String text,
  }) {
    final now = DateTime.now();
    return chat_core.Message.text(
      id: now.microsecondsSinceEpoch.toString(),
      authorId: author.id,
      createdAt: now,
      text: text,
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(right: 80, left: 16, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          const SizedBox(width: 6),
          _buildDot(1),
          const SizedBox(width: 6),
          _buildDot(2),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final value = (_typingAnimationController.value - (index * 0.2)) % 1.0;
        final opacity = (value < 0.5) ? value * 2 : (1 - value) * 2;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentAI.primaryColor.withValues(alpha:0.4 + (opacity * 0.6)),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _currentAI.primaryColor.withValues(alpha:opacity * 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Container(
      margin: const EdgeInsets.only(right: 60, left: 16, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.person, size: 28, color: Colors.grey.withValues(alpha:0.7)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          doctor['name'] ?? 'Dr. Ahmed Badaoui',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentAI.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['specialty'] ?? context.l10n.lungSpecialist,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.withValues(alpha:0.2),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFBE0A), size: 14),
                      const SizedBox(width: 2),
                      Text(
                        doctor['rating']?.toString() ?? '5.0',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey.withValues(alpha:0.2), size: 12),
                      const SizedBox(width: 2),
                      Text(
                        doctor['distance'] ?? '2km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.withValues(alpha:0.2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.withValues(alpha:0.2)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _currentAI.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  '10:30 - 11:30',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              context.l10n.lungCheckup,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.withValues(alpha:0.2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: _buildDrawer(),
      appBar: AppBar(
        toolbarHeight: 70,
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_currentAI.secondaryColor, _currentAI.primaryColor],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _currentAI.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _currentAI.name(context.l10n),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xFF1D1D1F),
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F2C1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.l10n.proMember.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFBE0A),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currentAI.specialty(context.l10n),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.withValues(alpha:0.2),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isStreaming
                        ? context.l10n.writingStatus
                        : _isConnected
                            ? context.l10n.online
                            : context.l10n.connecting,
                    style: TextStyle(
                      fontSize: 11,
                      color: _isStreaming
                          ? _currentAI.primaryColor
                          : _isConnected
                              ? _currentAI.primaryColor.withValues(alpha:0.8)
                              : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1D1D1F), size: 20),
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF1D1D1F), size: 20),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20, top: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                          ),
                          title: Text(
                            context.l10n.clearHistory,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            unawaited(_clearHistory());
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content area with messages
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Messages list
                Expanded(
                  child: StreamBuilder<List<chat_core.Message>>(
                    stream: Stream.value(_chatController?.messages ?? []),
                    initialData: _chatController?.messages ?? [],
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? [];
                      
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.only(
                          top: 16,
                          left: 0,
                          right: 0,
                          bottom: 160, // Augmenté de 140 à 160 pour plus d'espace
                        ),
                        itemCount: messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isTyping && index == 0) {
                            return _buildTypingIndicator();
                          }
                          
                          final messageIndex = _isTyping ? index - 1 : index;
                          final message = messages[messageIndex];
                          final isUser = message.authorId == _currentUser.id;
                          
                          if (message is chat_core.CustomMessage) {
                            final metadata = message.metadata;
                            if (metadata?['type'] == 'doctor_card') {
                              return _buildDoctorCard(metadata?['doctor'] ?? {});
                            }
                          }
                          
                          if (message is chat_core.TextMessage) {
                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.only(
                                  left: isUser ? 60 : 16,
                                  right: isUser ? 16 : 60,
                                  bottom: 12,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser 
                                      ? _currentAI.primaryColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha:0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isUser
                                    ? Text(
                                        message.text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          height: 1.5,
                                        ),
                                      )
                                    : _AssistantMarkdown(
                                        data: message.text,
                                        primaryColor: _currentAI.primaryColor,
                                      ),
                              ),
                            );
                          }
                          
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Message composer positioned above bottom nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 80, // Augmenté de 60 à 80 pour plus d'espace
            child: _buildComposer(),
          ),
          
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(currentLocation: '/chat/ai/new'),
          ),
        ],
      ),
    );
  }
}

class _AssistantMarkdown extends StatelessWidget {
  final String data;
  final Color primaryColor;

  const _AssistantMarkdown({
    required this.data,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF1D1D1F);

    return MarkdownBody(
      data: data,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        strong: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        em: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: textColor,
        ),
        h1: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        h2: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
        h3: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
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
        listBullet: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.9)),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: primaryColor.withValues(alpha: 0.6), width: 3)),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      ),
    );
  }
}
