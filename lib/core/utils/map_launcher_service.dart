import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class MapLauncherService {
  static Future<void> openGoogleMaps(double lat, double lng) async {
    final String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final String appleUrl = 'https://maps.apple.com/?q=$lat,$lng';

    if (kIsWeb) {
      // En WEB: Abrir siempre en nueva pestaña
      await launchUrl(Uri.parse(googleUrl));
    } else {
      // En MOBILE (Android/iOS)
      if (Platform.isAndroid) {
        final Uri intentUri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
        if (await canLaunchUrl(intentUri)) {
          await launchUrl(intentUri);
        } else {
          await launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        if (await canLaunchUrl(Uri.parse(appleUrl))) {
          await launchUrl(Uri.parse(appleUrl));
        } else {
          await launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication);
        }
      }
    }

    await launchUrl(
      Uri.parse(googleUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}