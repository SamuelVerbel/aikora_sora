import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Pide permisos y retorna la posición actual
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      return null;
    }
  }

  /// Calcula distancia en km entre dos coordenadas
  static double distanceInKm(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final meters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return meters / 1000;
  }

  /// Formatea la distancia para mostrar en UI
  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).toInt()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.toInt()} km';
  }
}
