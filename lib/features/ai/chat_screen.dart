import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_overlay.dart';
import '../ai/ai_engine.dart';
import '../explore/models/destination_model.dart';

/// RF-21 — Chat conversacional in-app impulsado por Sora (Groq/LLaMA).
/// Diseño premium con animaciones, typing indicator y sugerencias rápidas.
class ChatScreen extends StatefulWidget {
  final Destination? destination;
  const ChatScreen({super.key, this.destination});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final AiEngine _ai = AiEngine();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isOffline = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
    
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
    _animationController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070E17) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0B1520) : Colors.white,
        title: Row(
          children: [
            // Avatar Sora con animación y estado
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('✨', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isOffline ? Colors.orange : Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF0B1520) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sora',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                        : isDark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.grey[600],
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
          // Banner modo offline premium
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Modo sin conexión — respondiendo con información guardada',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Offline',
                      style: TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          // Lista de mensajes con animaciones
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return AnimationConfiguration.staggeredList(
                      position: _messages.length,
                      duration: const Duration(milliseconds: 400),
                      child: SlideAnimation(
                        verticalOffset: 30,
                        child: FadeInAnimation(
                          child: _TypingBubblePremium(isDark: isDark),
                        ),
                      ),
                    );
                  }
                  final message = _messages[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 30,
                      child: FadeInAnimation(
                        child: _MessageBubblePremium(
                          message: message,
                          isDark: isDark,
                          showTime: index == _messages.length - 1 ||
                              (index < _messages.length - 1 &&
                                  _messages[index].isUser !=
                                      _messages[index + 1].isUser),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Sugerencias rápidas premium
          if (_messages.length <= 1)
            _QuickSuggestionsPremium(
              destination: widget.destination,
              onTap: (suggestion) {
                _controller.text = suggestion;
                _sendMessage();
              },
              isDark: isDark,
            ),

          // Input premium
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111D2E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: _isOffline
                              ? 'Pregunta (modo offline)...'
                              : 'Pregúntale a Sora...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: _isTyping
                          ? null
                          : AppColors.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: _isTyping
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: _isTyping ? null : _sendMessage,
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: _isTyping
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
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
// MODELO DE MENSAJE
// ─────────────────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser})
      : time = DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// BURBUJA DE MENSAJE PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubblePremium extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;
  final bool showTime;

  const _MessageBubblePremium({
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
      padding: const EdgeInsets.only(bottom: 8),
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('✨', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.accent
                        : (isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.grey[100]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 20),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showTime)
            Padding(
              padding: EdgeInsets.only(
                top: 6,
                left: isUser ? 0 : 42,
                right: isUser ? 8 : 0,
                bottom: 4,
              ),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPING INDICATOR PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _TypingBubblePremium extends StatefulWidget {
  final bool isDark;
  const _TypingBubblePremium({required this.isDark});

  @override
  State<_TypingBubblePremium> createState() => _TypingBubblePremiumState();
}

class _TypingBubblePremiumState extends State<_TypingBubblePremium>
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
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
                    width: 8,
                    height: 8,
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
// SUGERENCIAS RÁPIDAS PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _QuickSuggestionsPremium extends StatelessWidget {
  final Destination? destination;
  final void Function(String) onTap;
  final bool isDark;

  const _QuickSuggestionsPremium({
    this.destination,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = destination != null
        ? [
            '¿Qué puedo hacer en ${destination!.city}?',
            '¿Cuál es el mejor clima para ir?',
            '¿Qué restaurantes recomiendas?',
            '¿Cómo llego desde Colombia?',
            '¿Qué presupuesto necesito?',
          ]
        : [
            '¿Destinos baratos en Latinoamérica?',
            '¿Qué necesito para viajar a Europa?',
            'Recomiéndame un destino de playa',
            '¿Cuándo es mejor viajar a Asia?',
            'Tips para viajar solo',
          ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => onTap(suggestions[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.question_mark,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    suggestions[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}