import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/env.dart';
import '../auth/services/preferences_service.dart';
import '../explore/models/destination_model.dart';
import 'user_behavior_service.dart';

/// RF-21 · RF-16 · RF-17
/// Motor de IA con modo híbrido: Groq online / fallback offline inteligente.
/// Caché LRU de 20 respuestas + retry automático con backoff ante 429/timeout.
class AiEngine {
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';
  static const int _maxTokens = 1024;
  static const int _cacheMaxSize = 20;

  static String get _apiKey => Env.groqApiKey;

  // UserBehaviorService disponible para extensiones futuras (RF-18)
  final UserBehaviorService _behavior = UserBehaviorService();

  final List<Map<String, String>> _chatHistory = [];

  /// Caché LRU: clave = hash(systemPrompt + userMessage), valor = respuesta
  final Map<String, String> _cache = {};
  final List<String> _cacheOrder = [];

  // Estado de conectividad detectable en runtime por chat_screen.dart
  bool _lastCallFailed = false;
  bool get isOffline => _lastCallFailed;
  bool get isConfigured => _apiKey.isNotEmpty;

  // ─── RF-21: Chat ──────────────────────────────────────────────────────────

  Future<String> chat(String userMessage, {Destination? destination}) async {
    final systemPrompt = _buildChatSystemPrompt(destination);
    final cacheKey = _cacheKey(systemPrompt, userMessage);

    // ── 1. Hit en caché: respuesta instantánea sin tocar la red ──────────
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      // Mantener historial coherente con la respuesta cacheada
      _chatHistory.add({'role': 'user', 'content': userMessage});
      _chatHistory.add({'role': 'assistant', 'content': cached});
      _lastCallFailed = false; // caché activo = sistema funciona
      return cached;
    }

    // ── 2. Añadir mensaje al historial solo cuando vamos a la red ────────
    _chatHistory.add({'role': 'user', 'content': userMessage});

    try {
      final response = await _callApiWithRetry(
        systemPrompt: systemPrompt,
        messages: List.from(_chatHistory),
      );
      _chatHistory.add({'role': 'assistant', 'content': response});
      _setCache(cacheKey, response);
      _lastCallFailed = false;
      return response;
    } catch (e) {
      debugPrint('[AiEngine] chat error: $e');
      _lastCallFailed = true;
      // Revertir el mensaje del usuario para que el historial no quede roto
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
      return _chatFallback(userMessage, destination: destination);
    }
  }

  void clearHistory() {
    _chatHistory.clear();
    _lastCallFailed = false;
  }

  // ─── System prompt ────────────────────────────────────────────────────────

  String _buildChatSystemPrompt(Destination? destination) {
    const base = '''
Eres Sora, el asistente de viajes de la app Aikōra Sora.
Eres amable, entusiasta y conciso. Respondes SIEMPRE en español.
Ayudas a los usuarios a planear viajes, conocer destinos y resolver dudas turísticas.
No generes información falsa sobre precios exactos o vuelos específicos.
Máximo 3 párrafos por respuesta. Usa emojis con moderación.
''';
    if (destination == null) return base;
    return '''
$base
El usuario está explorando: ${destination.title} en ${destination.city}, ${destination.country}.
Categoría: ${destination.category}. Clima: ${destination.climate}.
Precio desde: \$${destination.priceMin}. Rating: ${destination.rating}/5.
Mejor temporada: ${destination.bestSeason}.
Actividades destacadas: ${destination.activities.take(4).join(', ')}.
Descripción: ${destination.description}
Usa este contexto para responder preguntas específicas. Sé preciso con estos datos reales.
''';
  }

  // ─── Fallback offline inteligente ─────────────────────────────────────────

  /// Analiza la pregunta y usa los datos del destino (si hay) para dar
  /// una respuesta útil sin conexión. Nunca devuelve un mensaje genérico
  /// si tiene contexto suficiente para responder.
  String _chatFallback(String message, {Destination? destination}) {
    final lower = message.toLowerCase();

    // ── Con contexto de destino: respuestas basadas en datos reales ────────
    if (destination != null) {
      if (_matches(lower, ['precio', 'costo', 'cuánto', 'cuanto', 'vale', 'tarifa', 'económico'])) {
        return '${destination.title} tiene precios desde \$${destination.priceMin.toInt()} '
            'hasta \$${destination.priceMax.toInt()} por persona. '
            'La mejor época para precios bajos es fuera de ${destination.bestSeason}. 💰';
      }
      if (_matches(lower, ['clima', 'tiempo', 'temperatura', 'lluvia', 'calor', 'frío', 'frio'])) {
        return 'El clima de ${destination.title} es ${destination.climate}. '
            'La mejor época para visitarlo es ${destination.bestSeason}. '
            '¡Planifica con anticipación para aprovechar el mejor tiempo! ☀️';
      }
      if (_matches(lower, ['actividad', 'actividades', 'hacer', 'visitar', 'ver', 'recomiend', 'plan'])) {
        final acts = destination.activities.take(4).join(', ');
        return 'En ${destination.title} puedes disfrutar de: $acts. '
            'Con un rating de ${destination.rating}/5, '
            '¡es una de las mejores opciones en ${destination.country}! 🌟';
      }
      if (_matches(lower, ['hotel', 'hostal', 'alojamiento', 'dormir', 'hospedaje', 'quedar'])) {
        return 'Para hospedarte en ${destination.title} busca opciones en el centro de ${destination.city}. '
            'El rango de precios del destino va de \$${destination.priceMin.toInt()} '
            'a \$${destination.priceMax.toInt()} por noche. 🏨';
      }
      if (_matches(lower, ['restaurante', 'comida', 'comer', 'gastronomía', 'gastronomia', 'plato'])) {
        return 'Explora la sección de Restaurantes de ${destination.title} en la app '
            'para encontrar las mejores opciones locales en ${destination.city}. 🍽️';
      }
      if (_matches(lower, ['seguro', 'seguridad', 'peligro', 'riesgo'])) {
        return '${destination.title} tiene un rating de ${destination.rating}/5 '
            'según nuestra comunidad de viajeros. '
            'Siempre recomendamos consultar las alertas de viaje vigentes antes de salir. ✅';
      }
      if (_matches(lower, ['llegar', 'transporte', 'vuelo', 'bus', 'cómo ir', 'como ir', 'ruta'])) {
        return 'Para llegar a ${destination.city}, ${destination.country}, '
            'las opciones varían según tu origen. '
            'Reconecta para que te dé rutas y precios actualizados. ✈️';
      }
      // Fallback con contexto genérico del destino
      return '${destination.title} es un destino ${destination.category} en ${destination.city}, '
          '${destination.country}, con clima ${destination.climate} y rating '
          '${destination.rating}/5. ¡Sin duda una gran elección! '
          'Reconecta para preguntarme más detalles específicos. 🔄';
    }

    // ── Sin contexto de destino: respuestas turísticas generales ──────────
    if (_matches(lower, ['precio', 'costo', 'barato', 'económico', 'economico', 'presupuesto', 'dinero'])) {
      return 'Los destinos más económicos suelen estar en el sureste asiático, '
          'Centroamérica y el interior de Colombia. '
          'Con \$500-800 puedes tener una semana increíble en muchos de ellos. 💡';
    }
    if (_matches(lower, ['clima', 'tiempo', 'temporada', 'lluvia', 'verano', 'invierno'])) {
      return 'La mejor temporada depende del destino. En Colombia, diciembre-enero y '
          'junio-agosto son los meses más secos. Para el Caribe, evita septiembre-octubre. '
          'Reconecta para recomendaciones más precisas. ☀️';
    }
    if (_matches(lower, ['restaurante', 'comida', 'gastronomía', 'gastronomia', 'comer'])) {
      return 'Cada destino tiene su sección de Restaurantes en Aikōra Sora. '
          'Encuentra opciones locales, precios y ubicación desde el detalle del destino. 🍽️';
    }
    if (_matches(lower, ['europa', 'europe', 'españa', 'spain', 'italia', 'france', 'alemania'])) {
      return 'Para viajar a Europa desde Colombia necesitas pasaporte vigente y, '
          'en la mayoría de casos, visa Schengen. El proceso tarda entre 2-6 semanas. '
          'Reconecta para guiarte paso a paso. ✈️';
    }
    if (_matches(lower, ['colombia', 'cartagena', 'medellín', 'medellin', 'bogotá', 'bogota', 'eje cafetero'])) {
      return 'Colombia tiene destinos increíbles: Cartagena, el Eje Cafetero, '
          'la Amazonía y más. Explora la sección de destinos para verlos todos. '
          'Reconecta para recomendaciones personalizadas. 🇨🇴';
    }
    if (_matches(lower, ['playa', 'mar', 'caribe', 'costa', 'arena', 'oceano', 'océano'])) {
      return 'Las mejores playas para colombianos incluyen Cartagena, San Andrés, '
          'Santa Marta y destinos caribeños cercanos. '
          'Explora la categoría Playa en la app para ver todas las opciones. 🏖️';
    }
    if (_matches(lower, ['montaña', 'montana', 'nevado', 'trekking', 'senderismo', 'naturaleza', 'sierra'])) {
      return 'Para amantes de la montaña, Colombia ofrece el Eje Cafetero, '
          'Los Nevados y la Sierra Nevada. Internacionalmente, los Andes y los Alpes '
          'son referencias top. Reconecta para itinerarios completos. 🏔️';
    }
    if (_matches(lower, ['visa', 'pasaporte', 'requisito', 'documento', 'permiso', 'migración'])) {
      return 'Con pasaporte colombiano puedes entrar sin visa a más de 90 países. '
          'Para Europa necesitas visa Schengen; para EE.UU., visa B1/B2. '
          'Reconecta para verificar los requisitos exactos de tu destino. 📋';
    }
    if (_matches(lower, ['seguro', 'seguridad', 'peligro', 'seguro médico', 'seguro de viaje'])) {
      return 'Se recomienda siempre contratar un seguro de viaje con cobertura médica. '
          'Para Europa es obligatorio para obtener la visa Schengen. '
          'Reconecta para recomendaciones de aseguradoras. 🛡️';
    }

    // Fallback último recurso — más informativo que el anterior
    return 'Estoy sin conexión en este momento, pero puedo ayudarte con información '
        'guardada sobre clima, precios, actividades, requisitos de visa y más. '
        'Intenta ser más específico o reconecta para respuestas completas. 🔄';
  }

  /// Helper: true si el mensaje contiene alguna de las palabras clave
  bool _matches(String lower, List<String> keywords) =>
      keywords.any((k) => lower.contains(k));

  // ─── RF-17: Resumen de viaje ──────────────────────────────────────────────

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
      final result = await _callApiWithRetry(
        systemPrompt:
            'Eres Sora, asistente de viajes. Cálido y conciso. Solo español.',
        messages: [
          {'role': 'user', 'content': prompt}
        ],
      );
      _lastCallFailed = false;
      return result;
    } catch (e) {
      debugPrint('[AiEngine] Error resumen: $e');
      _lastCallFailed = true;
      final top = destinations.first;
      return 'Hoy exploraste ${destinations.length} destino${destinations.length > 1 ? 's' : ''}, '
          'incluyendo ${top.title} en ${top.city}. ¡Sigue descubriendo el mundo! ✈️';
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
Responde SOLO con los nombres exactos, uno por línea, sin numeración ni símbolos.
''';
    try {
      final response = await _callApiWithRetry(
        systemPrompt: 'Experto en logística de viajes. Responde en español.',
        messages: [
          {'role': 'user', 'content': prompt}
        ],
      );
      _lastCallFailed = false;
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
      // Añadir cualquier destino que el modelo no mencionó explícitamente
      for (final d in destinations) {
        if (!sorted.contains(d)) sorted.add(d);
      }
      return sorted;
    } catch (e) {
      debugPrint('[AiEngine] Error ruta: $e');
      _lastCallFailed = true;
      // Fallback: agrupar por país y luego por ciudad minimiza viajes
      final fallback = List<Destination>.from(destinations);
      fallback.sort((a, b) {
        final countryComp = a.country.compareTo(b.country);
        if (countryComp != 0) return countryComp;
        return a.city.compareTo(b.city);
      });
      return fallback;
    }
  }

  // ─── HTTP a Groq con retry automático ────────────────────────────────────

  /// Llama a la API. Si falla con 429 o timeout, reintenta una vez tras
  /// 1.5 segundos antes de lanzar la excepción definitiva al fallback.
  Future<String> _callApiWithRetry({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int attempt = 1,
  }) async {
    try {
      return await _callApi(systemPrompt: systemPrompt, messages: messages);
    } catch (e) {
      final isRetryable = e.toString().contains('429') ||
          e.toString().contains('Timeout') ||
          e.toString().contains('timeout') ||
          e.toString().contains('server error');
      if (attempt == 1 && isRetryable) {
        debugPrint('[AiEngine] Reintentando tras 1.5s (causa: $e)');
        await Future.delayed(const Duration(milliseconds: 1500));
        return _callApiWithRetry(
          systemPrompt: systemPrompt,
          messages: messages,
          attempt: 2,
        );
      }
      rethrow;
    }
  }

  Future<String> _callApi({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    if (_apiKey.isEmpty) throw Exception('GROQ_API_KEY no configurada');

    final fullMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final response = await http
        .post(
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
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception('Timeout de conexión'),
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else if (response.statusCode == 429) {
      throw Exception('429: Límite de solicitudes alcanzado.');
    } else if (response.statusCode >= 500) {
      throw Exception('Groq server error ${response.statusCode}');
    } else {
      throw Exception('Groq error ${response.statusCode}: ${response.body}');
    }
  }

  // ─── Caché LRU ───────────────────────────────────────────────────────────

  String _cacheKey(String system, String user) =>
      '${system.hashCode}:${user.toLowerCase().trim()}';

  void _setCache(String key, String value) {
    if (_cache.containsKey(key)) {
      _cacheOrder.remove(key);
    } else if (_cache.length >= _cacheMaxSize) {
      final oldest = _cacheOrder.removeAt(0);
      _cache.remove(oldest);
    }
    _cache[key] = value;
    _cacheOrder.add(key);
  }
}