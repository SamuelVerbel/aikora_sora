import 'package:url_launcher/url_launcher.dart';

class MapLauncherService {
  /// Abre Google Maps en las coordenadas específicas
  static Future<void> openMap(double lat, double lng, String name) async {
    // Usamos el esquema 'geo' para Android/iOS o la URL de búsqueda de Google
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir el mapa para $name';
    }
  }
}