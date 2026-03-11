import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/theme_provider.dart';
import '../auth/services/auth_service.dart';
import '../auth/services/profile_service.dart';
import '../auth/services/preferences_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;
  bool _isSavingPrefs = false;

  // Preferencias
  bool likesNature = true;
  bool likesCulture = false;
  bool likesFood = true;
  bool likesAdventure = false;
  bool likesBeach = false;
  double budget = 500;
  String selectedLanguage = 'es';

  final Map<String, String> languages = {
    'es': '🇪🇸 Español',
    'en': '🇺🇸 English',
    'pt': '🇧🇷 Português',
    'fr': '🇫🇷 Français',
    'de': '🇩🇪 Deutsch',
    'ja': '🇯🇵 日本語',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final results = await Future.wait([
      _profileService.getProfile(userId),
      PreferencesService.loadPreferences(),
    ]);

    final profile = results[0];
    final prefs = results[1] as Map<String, dynamic>;

    if (mounted) {
      setState(() {
        _profile = profile;
        likesNature = prefs['nature'] ?? true;
        likesCulture = prefs['culture'] ?? false;
        likesFood = prefs['food'] ?? true;
        likesAdventure = prefs['adventure'] ?? false;
        likesBeach = prefs['beach'] ?? false;
        selectedLanguage = prefs['language'] ?? 'es';
        budget = (prefs['budget'] ?? 500).toDouble();
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSavingPrefs = true);
    await PreferencesService.savePreferences(
    nature: likesNature,
    culture: likesCulture,
    food: likesFood,
    adventure: likesAdventure,
    beach: likesBeach,
    language: selectedLanguage,
    budget: budget,
  );
    if (mounted) {
      setState(() => _isSavingPrefs = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Preferencias guardadas'),
          ]),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false);
      }
    }
  }

  String _getMemberSince() {
    final raw = _profile?['created_at'];
    if (raw == null) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return 'Miembro desde ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _showEditProfileModal() async {
    final nameCtrl = TextEditingController(
        text: _profile?['full_name'] ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24, right: 24, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Editar perfil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon:
                    const Icon(Icons.person_outline, color: AppColors.accent),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  if (newName.isEmpty) return;
                  final userId = _supabase.auth.currentUser?.id;
                  if (userId == null) return;

                  await _profileService.updateProfile(
                      userId: userId, fullName: newName);

                  if (mounted) {
                    Navigator.pop(ctx);
                    setState(() =>
                        _profile = {...?_profile, 'full_name': newName});
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Row(children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Perfil actualizado'),
                      ]),
                      backgroundColor: AppColors.accent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                },
                child: const Text('Guardar',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
  }

  void _showPrivacyInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.shield_outlined, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              const Text('Privacidad y datos',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            _privacyItem(Icons.storage_outlined, 'Almacenamiento local',
                'Tus preferencias se guardan en tu dispositivo con SharedPreferences.'),
            _privacyItem(Icons.cloud_outlined, 'Datos en la nube',
                'Tu perfil y reservas se almacenan de forma segura en Supabase con encriptación.'),
            _privacyItem(Icons.no_photography_outlined, 'Sin seguimiento',
                'No vendemos ni compartimos tus datos con terceros.'),
            _privacyItem(Icons.lock_outlined, 'Autenticación segura',
                'Usamos OAuth 2.0 de Google y JWT tokens para proteger tu cuenta.'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _privacyItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(desc,
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildTravelStyle() {
    if (likesAdventure) return "Explorador aventurero";
    if (likesFood) return "Viajero gastronómico";
    if (likesCulture) return "Amante cultural";
    if (likesBeach) return "Buscador de relax";
    return "Viajero equilibrado";
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final fullName = _profile?['full_name'] ??
        _supabase.auth.currentUser?.email?.split('@').first ??
        'Viajero';
    final email =
        _profile?['email'] ?? _supabase.auth.currentUser?.email ?? '';
    final avatarUrl = _profile?['avatar_url'];
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'V';

    return Scaffold(
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // 🎨 Header tipo app premium
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0B1C2D),
                            Color(0xFF0F2744),
                            Color(0xFF14B8A6),
                          ],
                          stops: [0.0, 0.6, 1.0],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),

                            // Avatar
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent
                                            .withOpacity(0.4),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 48,
                                    backgroundColor:
                                        AppColors.accent.withOpacity(0.3),
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? Text(initials,
                                            style: const TextStyle(
                                                fontSize: 34,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white))
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.edit,
                                        size: 13, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            Text(fullName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(email,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 6),
                            if (_getMemberSince().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getMemberSince(),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 📄 Contenido
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // 🌙 Apariencia
                        _SectionTitle(title: 'Apariencia'),
                        _SettingsCard(children: [
                          SwitchListTile(
                            title: const Text('Modo oscuro',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(isDark ? 'Activado' : 'Desactivado',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12)),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDark ? Icons.dark_mode : Icons.light_mode,
                                color: AppColors.accent,
                                size: 20,
                              ),
                            ),
                            value: isDark,
                            activeColor: AppColors.accent,
                            onChanged: themeProvider.toggleTheme,
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // 🌍 Idioma
                        _SectionTitle(title: 'Idioma'),
                        _SettingsCard(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: DropdownButtonFormField<String>(
                              value: selectedLanguage,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.language,
                                    color: AppColors.accent, size: 20),
                              ),
                              items: languages.entries
                                  .map((e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedLanguage = v!),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        _SectionTitle(title: 'Tu estilo de viaje'),
                        _SettingsCard(children: [
                          ListTile(
                            leading: Icon(Icons.auto_awesome, color: AppColors.accent),
                            title: Text(_buildTravelStyle()),
                            subtitle: Text(
                              'Basado en tus preferencias y actividad reciente',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ]),

                        // 🎯 Preferencias de viaje
                        _SectionTitle(title: 'Preferencias de viaje'),
                        _SettingsCard(children: [
                          _PrefTile(
                            icon: Icons.forest_outlined,
                            label: 'Naturaleza',
                            value: likesNature,
                            onChanged: (v) =>
                                setState(() => likesNature = v),
                          ),
                          const _Divider(),
                          _PrefTile(
                            icon: Icons.museum_outlined,
                            label: 'Cultura e historia',
                            value: likesCulture,
                            onChanged: (v) =>
                                setState(() => likesCulture = v),
                          ),
                          const _Divider(),
                          _PrefTile(
                            icon: Icons.restaurant_outlined,
                            label: 'Gastronomía',
                            value: likesFood,
                            onChanged: (v) => setState(() => likesFood = v),
                          ),
                          const _Divider(),
                          _PrefTile(
                            icon: Icons.hiking_outlined,
                            label: 'Aventura',
                            value: likesAdventure,
                            onChanged: (v) =>
                                setState(() => likesAdventure = v),
                          ),
                          const _Divider(),
                          _PrefTile(
                            icon: Icons.beach_access_outlined,
                            label: 'Playa y relax',
                            value: likesBeach,
                            onChanged: (v) => setState(() => likesBeach = v),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // 💰 Presupuesto
                        _SectionTitle(title: 'Presupuesto por noche'),
                        _SettingsCard(children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Máximo por noche',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '\$${budget.toInt()} USD',
                                    style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Slider(
                            min: 50,
                            max: 3000,
                            divisions: 59,
                            value: budget,
                            activeColor: AppColors.accent,
                            onChanged: (v) => setState(() => budget = v),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('\$50',
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12)),
                                Text('\$3,000',
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Botón guardar preferencias
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: _isSavingPrefs
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined,
                                    color: Colors.white),
                            label: Text(
                                _isSavingPrefs
                                    ? 'Guardando...'
                                    : 'Guardar preferencias',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed:
                                _isSavingPrefs ? null : _savePreferences,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ⚙️ Cuenta
                        _SectionTitle(title: 'Cuenta'),
                        _SettingsCard(children: [
                          _ActionTile(
                            icon: Icons.person_outline,
                            label: 'Editar perfil',
                            color: AppColors.accent,
                            onTap: _showEditProfileModal,
                          ),
                          const _Divider(),
                          _ActionTile(
                            icon: Icons.shield_outlined,
                            label: 'Privacidad y datos',
                            color: AppColors.accent,
                            onTap: _showPrivacyInfo,
                          ),
                          const _Divider(),
                          _ActionTile(
                            icon: Icons.logout,
                            label: 'Cerrar sesión',
                            color: Colors.red,
                            onTap: _signOut,
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // Versión
                        Center(
                          child: Text(
                            'Aikōra Sora v1.0.0 · Hecho con ❤️ en Cartagena',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* ── Widgets auxiliares ─────────────────────────── */

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value
              ? AppColors.accent.withOpacity(0.12)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: value ? AppColors.accent : Colors.grey, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      value: value,
      activeColor: AppColors.accent,
      onChanged: onChanged,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1, indent: 60, color: Colors.grey.withOpacity(0.15));
  }
}
