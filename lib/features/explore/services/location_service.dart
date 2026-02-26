import 'package:geolocator/geolocator.dart';

/// Servicio responsable de manejar la ubicación del dispositivo (GPS).
/// Centraliza la solicitud de permisos y cálculos matemáticos de distancia.
class LocationService {
  
  /// Pide permisos al usuario y retorna sus coordenadas actuales.
  /// Si el usuario deniega el permiso o tiene el GPS apagado, retorna null.
  static Future<Position?> getCurrentPosition() async {
    try {
      // 1. Verifica si el GPS del teléfono está encendido
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // 2. Verifica qué permisos tenemos actualmente
      LocationPermission permission = await Geolocator.checkPermission();
      
      // 3. Si no tenemos permiso, se lo pedimos al usuario con un popup del SO
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        // Si el usuario dijo que "No" en el popup
        if (permission == LocationPermission.denied) return null;
      }
      
      // 4. Si el usuario bloqueó permanentemente los permisos en ajustes
      if (permission == LocationPermission.deniedForever) return null;

      // 5. Todo OK, obtenemos latitud y longitud.
      // Usamos accuracy "medium" y un timeout de 8s para no demorar ni gastar mucha batería.
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      // Atrapa cualquier error raro del sistema operativo y evita crashear la app
      return null;
    }
  }

  /// Calcula la distancia en kilómetros entre el punto 1 (Usuario) y punto 2 (Destino).
  static double distanceInKm(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    // distanceBetween usa la fórmula de Haversine para calcular distancia en un globo terráqueo.
    // Retorna la distancia en metros.
    final meters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return meters / 1000; // Convertimos a KM
  }

  /// Formatea el número de la distancia para que se vea bonito en la interfaz.
  static String formatDistance(double km) {
    // Si está a menos de 1km, lo muestra en metros (ej: 450 m)
    if (km < 1) return '${(km * 1000).toInt()} m';
    
    // Si está a menos de 10km, muestra 1 decimal (ej: 4.2 km)
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    
    // Si está lejos, muestra enteros sin decimales para no saturar (ej: 1450 km)
    return '${km.toInt()} km';
  }
}
