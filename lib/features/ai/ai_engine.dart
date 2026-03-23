import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/env.dart';
import '../auth/services/preferences_service.dart';
import '../explore/models/destination_model.dart';
import 'user_behavior_service.dart';

class AiEngine {
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  // FIX: modelo actualizado — llama3-8b-8192 fue deprecado
  static const String _model = 'llama-3.1-8b-instant';
  static const int _maxTokens = 1024;

  static String get _apiKey => Env.groqApiKey;

  final UserBehaviorService _behavior = UserBehaviorService();
  final List<Map<String, String>> _chatHistory = [];

  // ─── RF-21: Chat ──────────────────────────────────────────────────────────

  Future<String> chat(String userMessage, {Destination? destination}) async {
    final systemPrompt = _buildChatSystemPrompt(destination);
    _chatHistory.add({'role': 'user', 'content': userMessage});

    try {
      final response = await _callApi(
        systemPrompt: systemPrompt,
        messages: List.from(_chatHistory),
      );
      _chatHistory.add({'role': 'assistant', 'content': response});
      return response;
    } catch (e) {
      debugPrint('[AiEngine] Error en chat: $e');
      if (_chatHistory.isNotEmpty) _chatHistory.removeLast();
      return _chatFallback(userMessage);
    }
  }

  void clearHistory() => _chatHistory.clear();

  String _buildChatSystemPrompt(Destination? destination) {
    final base = '''
Eres Sora, el asistente de viajes de la app Aikōra Sora.
Eres amable, entusiasta y conciso. Respondes SIEMPRE en español.
Ayudas a los usuarios a planear viajes, conocer destinos y resolver dudas turísticas.
No generes información falsa sobre precios o vuelos específicos.
Máximo 3 párrafos por respuesta.
''';
    if (destination == null) return base;
    return '''
$base
El usuario está viendo: ${destination.title} en ${destination.city}, ${destination.country}.
Categoría: ${destination.category}. Clima: ${destination.climate}.
Precio desde: \$${destination.priceMin}. Rating: ${destination.rating}/5.
Descripción: ${destination.description}
Usa este contexto para responder preguntas específicas sobre este destino.
''';
  }

  String _chatFallback(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('precio') || lower.contains('costo')) {
      return 'Los precios varían según la temporada. Revisa la sección de detalles del destino para información actualizada. 🌍';
    }
    if (lower.contains('clima') || lower.contains('tiempo')) {
      return 'El clima depende de la época del año. La mejor temporada suele ser entre abril y octubre en el hemisferio norte. ☀️';
    }
    if (lower.contains('restaurante') || lower.contains('comida')) {
      return 'Puedes explorar los restaurantes cercanos en la sección de cada destino. 🍽️';
    }
    return 'Sin conexión en este momento. Verifica tu internet e intenta de nuevo. 🔄';
  }

  // ─── RF-17: Resumen ───────────────────────────────────────────────────────

  Future<String> generateTripSummary(List<Destination> destinations) async {
    if (destinations.isEmpty) {
      return 'Hoy no exploraste ningún destino. ¡Mañana es un buen día para descubrir el mundo! 🌎';
    }
    final destList = destinations
        .map((d) => '- ${d.title} (${d.city}, ${d.country})')
        .join('\n');
    final prefs = await PreferencesService.loadPreferences();
    final budget = prefs['budget']?.toString() ?? 'no especificado';
    final prompt = '''
El usuario exploró hoy en Aikōra Sora:
$destList
Presupuesto: \$$budget
Genera un resumen amigable en máximo 3 oraciones. Menciona un destino
destacado y sugiere un próximo paso. Solo español, directo al resumen.
''';
    try {
      return await _callApi(
        systemPrompt:
            'Eres Sora, asistente de viajes. Cálido y conciso. Solo español.',
        messages: [
          {'role': 'user', 'content': prompt}
        ],
      );
    } catch (e) {
      debugPrint('[AiEngine] Error resumen: $e');
      return 'Hoy exploraste ${destinations.length} destino${destinations.length > 1 ? 's' : ''}, incluyendo ${destinations.first.title}. ¡Sigue descubriendo el mundo! ✈️';
    }
  }

  // ─── RF-16: Ruta optimizada ───────────────────────────────────────────────

  Future<List<Destination>> suggestOptimizedRoute(
    List<Destination> destinations, {
    String? currentCity,
  }) async {
    if (destinations.length <= 1) return destinations;
    final destList = destinations
        .map((d) => '${d.title} en ${d.city}, ${d.country}')
        .join('; ');
    final origin = currentCity != null ? 'Partiendo desde $currentCity. ' : '';
    final prompt = '''
${origin}Destinos: $destList
Ordénalos geográficamente para minimizar viajes.
Responde SOLO con los nombres exactos, uno por línea, sin numeración.
''';
    try {
      final response = await _callApi(
        systemPrompt: 'Experto en logística de viajes. Responde en español.',
        messages: [
          {'role': 'user', 'content': prompt}
        ],
      );
      final suggestedNames = response
          .split('\n')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();
      final sorted = <Destination>[];
      for (final name in suggestedNames) {
        final match = destinations.where(
          (d) =>
              d.title.toLowerCase().contains(name) ||
              name.contains(d.title.toLowerCase()),
        );
        if (match.isNotEmpty && !sorted.contains(match.first)) {
          sorted.add(match.first);
        }
      }
      for (final d in destinations) {
        if (!sorted.contains(d)) sorted.add(d);
      }
      return sorted;
    } catch (e) {
      debugPrint('[AiEngine] Error ruta: $e');
      final fallback = List<Destination>.from(destinations);
      fallback.sort((a, b) => a.country.compareTo(b.country));
      return fallback;
    }
  }

  // ─── HTTP a Groq ──────────────────────────────────────────────────────────

  Future<String> _callApi({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    if (_apiKey.isEmpty) throw Exception('GROQ_API_KEY no configurada');

    final fullMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': _maxTokens,
        'messages': fullMessages,
      }),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Timeout de conexión'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('Groq error ${response.statusCode}: ${response.body}');
    }
  }

  bool get isConfigured => _apiKey.isNotEmpty;
}