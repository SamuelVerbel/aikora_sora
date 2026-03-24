import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class MapLauncherService {
  /// Abre Google Maps buscando por nombre + dirección
  static Future<void> openGoogleMapsWithName({
    required String name,
    required double lat,
    required double lng,
    String? address,
  }) async {
    final query = Uri.encodeComponent(
      address != null && address.isNotEmpty ? '$name, $address' : name,
    );
    final String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$query';

    try {
      if (kIsWeb) {
        await launchUrl(Uri.parse(googleUrl),
            mode: LaunchMode.externalApplication);
        return;
      }

      if (Platform.isAndroid) {
        final Uri intentUri =
            Uri.parse('geo:$lat,$lng?q=${Uri.encodeComponent(name)}');
        if (await canLaunchUrl(intentUri)) {
          await launchUrl(intentUri);
          return;
        }
        await launchUrl(Uri.parse(googleUrl),
            mode: LaunchMode.externalApplication);
        return;
      }

      if (Platform.isIOS) {
        final String appleUrl =
            'https://maps.apple.com/?q=${Uri.encodeComponent(name)}&ll=$lat,$lng';
        if (await canLaunchUrl(Uri.parse(appleUrl))) {
          await launchUrl(Uri.parse(appleUrl));
          return;
        }
        await launchUrl(Uri.parse(googleUrl),
            mode: LaunchMode.externalApplication);
        return;
      }

      await launchUrl(Uri.parse(googleUrl),
          mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('MapLauncherService error: $e');
    }
  }

  /// Método original mantenido por compatibilidad
  static Future<void> openGoogleMaps(double lat, double lng) async {
    await openGoogleMapsWithName(name: 'Lugar', lat: lat, lng: lng);
  }
}