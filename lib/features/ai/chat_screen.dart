import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../ai/ai_engine.dart';
import '../explore/models/destination_model.dart';

/// RF-21 — Chat conversacional in-app impulsado por Sora (Groq/LLaMA).
/// Soporta modo offline con fallback inteligente.
/// Se puede abrir desde la navegación principal o desde el detalle de un destino.
class ChatScreen extends StatefulWidget {
  final Destination? destination;
  const ChatScreen({super.key, this.destination});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AiEngine _ai = AiEngine();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    final welcome = widget.destination != null
        ? '¡Hola! Soy Sora 🌏 Veo que estás explorando **${widget.destination!.title}**. ¿Qué quieres saber sobre este destino?'
        : '¡Hola! Soy Sora, tu asistente de viajes ✈️ ¿A dónde quieres ir hoy?';
    _messages.add(_ChatMessage(text: welcome, isUser: false));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _ai.clearHistory();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    final response = await _ai.chat(text, destination: widget.destination);

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false));
        _isTyping = false;
        _isOffline = _ai.isOffline;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Avatar Sora con indicador de estado
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accent.withOpacity(0.15),
                  child: const Text('✨', style: TextStyle(fontSize: 16)),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _isOffline ? Colors.orange : Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sora',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  _isOffline
                      ? 'Modo sin conexión'
                      : (widget.destination != null
                          ? widget.destination!.title
                          : 'Asistente de viajes'),
                  style: TextStyle(
                    fontSize: 11,
                    color: _isOffline
                        ? Colors.orange
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Limpiar conversación',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _ai.clearHistory();
              setState(() {
                _messages.clear();
                _isOffline = false;
                _messages.add(_ChatMessage(
                  text: '¡Conversación reiniciada! ¿En qué te puedo ayudar? 🌍',
                  isUser: false,
                ));
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Banner modo offline ──────────────────────────────────────────
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.withOpacity(0.12),
              child: Row(children: [
                const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sin conexión — respondiendo con información guardada',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ]),
            ),

          // ── Lista de mensajes ────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _TypingBubble(isDark: isDark);
                }
                return _MessageBubble(
                  message: _messages[index],
                  isDark: isDark,
                  showTime: index == _messages.length - 1 ||
                      (index < _messages.length - 1 &&
                          _messages[index].isUser !=
                              _messages[index + 1].isUser),
                );
              },
            ),
          ),

          // ── Sugerencias rápidas (solo al inicio) ────────────────────────
          if (_messages.length <= 1)
            _QuickSuggestions(
              destination: widget.destination,
              onTap: (suggestion) {
                _controller.text = suggestion;
                _sendMessage();
              },
            ),

          // ── Input ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isOffline
                            ? 'Pregunta (modo offline)...'
                            : 'Pregúntale a Sora...',
                        hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.4)),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.07)
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: FloatingActionButton.small(
                      heroTag: 'chat_send',
                      onPressed: _isTyping ? null : _sendMessage,
                      backgroundColor:
                          _isTyping ? Colors.grey[400] : AppColors.accent,
                      elevation: 0,
                      child: _isTyping
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de mensaje
// ─────────────────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser})
      : time = DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// Burbuja de mensaje
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;
  final bool showTime;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    this.showTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr =
        '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent.withOpacity(0.15),
                  child: const Text('✨', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.accent
                        : (isDark
                            ? Colors.white.withOpacity(0.09)
                            : Colors.grey[100]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          if (showTime)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isUser ? 0 : 40,
                right: isUser ? 8 : 0,
                bottom: 8,
              ),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.35),
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animación "escribiendo..."
// ─────────────────────────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  final bool isDark;
  const _TypingBubble({required this.isDark});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _animations = _controllers
        .map((c) => Tween(begin: 0.3, end: 1.0).animate(c))
        .toList();

    // Stagger: cada punto arranca 150ms después
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.accent.withOpacity(0.15),
            child: const Text('✨', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.09)
                  : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => FadeTransition(
                  opacity: _animations[i],
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sugerencias rápidas
// ─────────────────────────────────────────────────────────────────────────────

class _QuickSuggestions extends StatelessWidget {
  final Destination? destination;
  final void Function(String) onTap;

  const _QuickSuggestions({this.destination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = destination != null
        ? [
            '¿Qué puedo hacer en ${destination!.city}?',
            '¿Cuál es el mejor clima para ir?',
            '¿Qué restaurantes recomiendas?',
            '¿Cómo llego desde Colombia?',
          ]
        : [
            '¿Destinos baratos en Latinoamérica?',
            '¿Qué necesito para viajar a Europa?',
            'Recomiéndame un destino de playa',
            '¿Cuándo es mejor viajar a Asia?',
          ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) => ActionChip(
            label: Text(suggestions[i], style: const TextStyle(fontSize: 12)),
            onPressed: () => onTap(suggestions[i]),
            backgroundColor: AppColors.accent.withOpacity(0.08),
            side: BorderSide(color: AppColors.accent.withOpacity(0.25)),
            labelStyle: const TextStyle(color: AppColors.accent),
          ),
        ),
      ),
    );
  }
}