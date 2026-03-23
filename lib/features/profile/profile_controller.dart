import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/services/profile_service.dart';
import '../auth/services/preferences_service.dart';

/// Controlador que separa la lógica de negocio de la UI del perfil.
/// Usa ChangeNotifier para que ProfileScreen escuche cambios con ListenableBuilder.
class ProfileController extends ChangeNotifier {
  final ProfileService _profileService;
  final SupabaseClient _supabase;

  ProfileController({
    ProfileService? profileService,
    SupabaseClient? supabase,
  })  : _profileService = profileService ?? ProfileService(),
        _supabase = supabase ?? Supabase.instance.client;

  // ── Estado del perfil ──
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  bool _isLoadingProfile = true;
  bool get isLoadingProfile => _isLoadingProfile;

  bool _isSavingPrefs = false;
  bool get isSavingPrefs => _isSavingPrefs;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _memberSince = '';
  String get memberSince => _memberSince;

  // ── Preferencias ──
  bool likesNature = true;
  bool likesCulture = false;
  bool likesFood = true;
  bool likesAdventure = false;
  bool likesBeach = false;
  double budget = 500;
  String selectedLanguage = 'es';

  // Track de cambios sin guardar
  bool _hasUnsavedChanges = false;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  // Snapshot de las preferencias al momento de cargar
  Map<String, dynamic> _savedSnapshot = {};

  // ── Datos derivados ──
  String get fullName =>
      _profile?['full_name'] ??
      _supabase.auth.currentUser?.email?.split('@').first ??
      'Viajero';

  String get email =>
      _profile?['email'] ?? _supabase.auth.currentUser?.email ?? '';

  String? get avatarUrl => _profile?['avatar_url'];

  String get initials =>
      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'V';

  String? get userId => _supabase.auth.currentUser?.id;

  static const Map<String, String> languages = {
    'es': '🇪🇸 Español',
    'en': '🇺🇸 English',
    'pt': '🇧🇷 Português',
    'fr': '🇫🇷 Français',
    'de': '🇩🇪 Deutsch',
    'ja': '🇯🇵 日本語',
  };

  // ── Carga de datos ──

  Future<void> loadData() async {
    final uid = userId;
    if (uid == null) {
      _isLoadingProfile = false;
      _errorMessage = 'No hay sesión activa';
      notifyListeners();
      return;
    }

    try {
      // Ejecutamos ambas peticiones en paralelo, pero de forma resiliente
      final profileFuture = _profileService.getProfile(uid);
      final prefsFuture = PreferencesService.loadPreferences();

      final results = await Future.wait<dynamic>(
        [profileFuture, prefsFuture],
        eagerError: false,
      );

      _profile = results[0] as Map<String, dynamic>?;
      final prefs = results[1] as Map<String, dynamic>;

      likesNature = prefs['nature'] ?? true;
      likesCulture = prefs['culture'] ?? false;
      likesFood = prefs['food'] ?? true;
      likesAdventure = prefs['adventure'] ?? false;
      likesBeach = prefs['beach'] ?? false;
      selectedLanguage = prefs['language'] ?? 'es';
      budget = (prefs['budget'] ?? 500).toDouble();

      _savedSnapshot = _currentPrefsSnapshot();
      _hasUnsavedChanges = false;
      _memberSince = _computeMemberSince();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar el perfil. Intenta de nuevo.';
      debugPrint('ProfileController.loadData error: $e');
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // ── Guardar preferencias ──

  Future<bool> savePreferences() async {
    _isSavingPrefs = true;
    notifyListeners();

    try {
      await PreferencesService.savePreferences(
        nature: likesNature,
        culture: likesCulture,
        food: likesFood,
        adventure: likesAdventure,
        beach: likesBeach,
        language: selectedLanguage,
        budget: budget,
      );

      _savedSnapshot = _currentPrefsSnapshot();
      _hasUnsavedChanges = false;
      _isSavingPrefs = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSavingPrefs = false;
      _errorMessage = 'Error al guardar preferencias';
      notifyListeners();
      debugPrint('ProfileController.savePreferences error: $e');
      return false;
    }
  }

  // ── Actualizar perfil (nombre) ──

  Future<bool> updateProfileName(String newName) async {
    final uid = userId;
    if (uid == null) return false;

    try {
      await _profileService.updateProfile(userId: uid, fullName: newName);
      _profile = {...?_profile, 'full_name': newName};
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ProfileController.updateProfileName error: $e');
      return false;
    }
  }

  // ── Actualizar avatar ──

  Future<bool> updateAvatar(String newAvatarUrl) async {
    final uid = userId;
    if (uid == null) return false;

    try {
      await _profileService.updateProfile(userId: uid, avatarUrl: newAvatarUrl);
      _profile = {...?_profile, 'avatar_url': newAvatarUrl};
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ProfileController.updateAvatar error: $e');
      return false;
    }
  }

  // ── Setters de preferencias con tracking de cambios ──

  void setNature(bool v) {
    likesNature = v;
    _checkUnsavedChanges();
  }

  void setCulture(bool v) {
    likesCulture = v;
    _checkUnsavedChanges();
  }

  void setFood(bool v) {
    likesFood = v;
    _checkUnsavedChanges();
  }

  void setAdventure(bool v) {
    likesAdventure = v;
    _checkUnsavedChanges();
  }

  void setBeach(bool v) {
    likesBeach = v;
    _checkUnsavedChanges();
  }

  void setBudget(double v) {
    budget = v;
    _checkUnsavedChanges();
  }

  void setLanguage(String v) {
    selectedLanguage = v;
    _checkUnsavedChanges();
  }

  // ── Estilo de viaje combinado ──

  String buildTravelStyle() {
    final styles = <String>[];
    if (likesAdventure) styles.add('aventurero');
    if (likesFood) styles.add('gastronómico');
    if (likesCulture) styles.add('cultural');
    if (likesBeach) styles.add('playero');
    if (likesNature) styles.add('naturalista');

    if (styles.isEmpty) return 'Viajero equilibrado';
    if (styles.length == 1) return 'Viajero ${styles.first}';
    if (styles.length == 2) return 'Viajero ${styles[0]} y ${styles[1]}';

    // 3+: primeros con coma, último con "y"
    final last = styles.removeLast();
    return 'Viajero ${styles.join(', ')} y $last';
  }

  // ── Helpers privados ──

  String _computeMemberSince() {
    final raw = _profile?['created_at'];
    if (raw == null) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return 'Miembro desde ${months[date.month - 1]} ${date.year}';
  }

  Map<String, dynamic> _currentPrefsSnapshot() => {
        'nature': likesNature,
        'culture': likesCulture,
        'food': likesFood,
        'adventure': likesAdventure,
        'beach': likesBeach,
        'language': selectedLanguage,
        'budget': budget,
      };

  void _checkUnsavedChanges() {
    final current = _currentPrefsSnapshot();
    _hasUnsavedChanges = current.toString() != _savedSnapshot.toString();
    notifyListeners();
  }
}
