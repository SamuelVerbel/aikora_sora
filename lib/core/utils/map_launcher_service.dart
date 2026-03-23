import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class MapLauncherService {
  static Future<void> openGoogleMaps(double lat, double lng) async {
    final String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final String appleUrl = 'https://maps.apple.com/?q=$lat,$lng';

    try {
      if (kIsWeb) {
        // Web: abre en nueva pestaña
        await launchUrl(Uri.parse(googleUrl),
            mode: LaunchMode.externalApplication);
        return;
      }

      if (Platform.isAndroid) {
        // Android: intenta abrir Google Maps nativo primero
        final Uri intentUri =
            Uri.parse('google.navigation:q=$lat,$lng&mode=d');
        if (await canLaunchUrl(intentUri)) {
          await launchUrl(intentUri);
          return;
        }
        // Fallback: abre en navegador
        await launchUrl(Uri.parse(googleUrl),
            mode: LaunchMode.externalApplication);
        return;
      }

      if (Platform.isIOS) {
        // iOS: intenta Apple Maps primero
        if (await canLaunchUrl(Uri.parse(appleUrl))) {
          await launchUrl(Uri.parse(appleUrl));
          return;
        }
        // Fallback: Google Maps en navegador
        await launchUrl(Uri.parse(googleUrl),
            mode: LaunchMode.externalApplication);
        return;
      }

      // Otras plataformas (desktop, etc.)
      await launchUrl(Uri.parse(googleUrl),
          mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('MapLauncherService error: $e');
    }
  }
}