import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../ai/ai_engine.dart';
import '../explore/models/destination_model.dart';

/// RF-21 — Chat conversacional in-app impulsado por Sora (Groq/LLaMA).
/// Se puede abrir desde la navegación principal o desde el detalle de un destino.
class ChatScreen extends StatefulWidget {
  /// Destino opcional — si viene, el chat tiene contexto de ese lugar.
  final Destination? destination;

  const ChatScreen({super.key, this.destination});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AiEngine _ai = AiEngine();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida contextual
    final welcome = widget.destination != null
        ? '¡Hola! Soy Sora 🌏 Veo que estás explorando **${widget.destination!.title}**. ¿Qué quieres saber sobre este destino?'
        : '¡Hola! Soy Sora, tu asistente de viajes ✈️ ¿A dónde quieres ir hoy?';

    _messages.add(_ChatMessage(text: welcome, isUser: false));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

    final response = await _ai.chat(
      text,
      destination: widget.destination,
    );

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accent.withOpacity(0.15),
              child: const Text('✨', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sora',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  widget.destination != null
                      ? widget.destination!.title
                      : 'Asistente de viajes',
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
          // ── Lista de mensajes ─────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Burbuja de "escribiendo..."
                if (_isTyping && index == _messages.length) {
                  return _TypingBubble(isDark: isDark);
                }
                return _MessageBubble(
                  message: _messages[index],
                  isDark: isDark,
                );
              },
            ),
          ),

          // ── Sugerencias rápidas (solo al inicio) ─────────────────────────
          if (_messages.length <= 1)
            _QuickSuggestions(
              destination: widget.destination,
              onTap: (suggestion) {
                _controller.text = suggestion;
                _sendMessage();
              },
            ),

          // ── Input ─────────────────────────────────────────────────────────
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
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      minLines: 1,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Pregúntale a Sora...',
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
                  // Botón enviar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: FloatingActionButton.small(
                      heroTag: 'chat_send',
                      onPressed: _isTyping ? null : _sendMessage,
                      backgroundColor:
                          _isTyping ? Colors.grey[400] : AppColors.accent,
                      elevation: 0,
                      child: const Icon(Icons.send_rounded,
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

  _ChatMessage({
    required this.text,
    required this.isUser,
  }) : time = DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// Burbuja de mensaje
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar de Sora
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.accent.withOpacity(0.15),
              child: const Text('✨', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],

          // Burbuja
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  height: 1.4,
                ),
              ),
            ),
          ),

          // Espacio para mensajes del usuario
          if (isUser) const SizedBox(width: 8),
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: FadeTransition(
              opacity: _animation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => _Dot(delay: i * 150)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: CircleAvatar(
        radius: 4,
        backgroundColor: AppColors.accent.withOpacity(0.6),
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

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(suggestions[i],
              style: const TextStyle(fontSize: 12)),
          onPressed: () => onTap(suggestions[i]),
          backgroundColor: AppColors.accent.withOpacity(0.08),
          side: BorderSide(color: AppColors.accent.withOpacity(0.25)),
          labelStyle: const TextStyle(color: AppColors.accent),
        ),
      ),
    );
  }
}