import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  static Future<void> openGoogleMaps(double lat, double lng) async {
    // Esta URL abre Google Maps directamente en modo navegación
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      // Si no tiene la app instalada, lo abrimos en el navegador
      final Uri webUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }
}