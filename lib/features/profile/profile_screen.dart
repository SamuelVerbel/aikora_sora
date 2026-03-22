import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/theme_provider.dart';
import '../auth/services/auth_service.dart';
import 'profile_controller.dart';
import 'widgets/edit_profile_modal.dart';
import 'widgets/privacy_info_sheet.dart';
import 'widgets/profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  late final ProfileController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ProfileController();
    _ctrl.addListener(_onControllerChanged);
    _ctrl.loadData();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // ── Acciones ──

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                borderRadius: BorderRadius.circular(12),
              ),
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

  Future<void> _handleSavePreferences() async {
    final success = await _ctrl.savePreferences();
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Preferencias guardadas'),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Error al guardar. Intenta de nuevo.'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _handleEditProfile() {
    EditProfileModal.show(
      context,
      currentName: _ctrl.fullName,
      onSave: (newName) => _ctrl.updateProfileName(newName),
    ).then((saved) {
      if (saved == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Perfil actualizado'),
              ],
            ),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }

  /// Bug #1 fix: Diálogo para cambiar avatar con URL.
  /// En una versión futura puedes reemplazar esto con image_picker + Supabase Storage.
  void _handleEditAvatar() {
    final urlCtrl = TextEditingController(text: _ctrl.avatarUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cambiar foto de perfil',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa la URL de tu nueva foto de perfil',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: urlCtrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'URL de la imagen',
                hintText: 'https://ejemplo.com/mi-foto.jpg',
                prefixIcon: const Icon(
                  Icons.image_outlined,
                  color: AppColors.accent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Actualizar foto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final url = urlCtrl.text.trim();
                  if (url.isEmpty) return;
                  final success = await _ctrl.updateAvatar(url);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Foto actualizada'),
                          backgroundColor: AppColors.accent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((_) => urlCtrl.dispose());
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Error state
    if (_ctrl.errorMessage != null && !_ctrl.isLoadingProfile) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _ctrl.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    _ctrl.loadData();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: _ctrl.isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Header ──
                _buildHeader(),

                // ── Contenido ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Indicador de cambios sin guardar (UX #8)
                        if (_ctrl.hasUnsavedChanges) _buildUnsavedBanner(),

                        // Apariencia
                        const ProfileSectionTitle(title: 'Apariencia'),
                        SettingsCard(
                          children: [
                            SwitchListTile(
                              title: const Text(
                                'Modo oscuro',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                isDark ? 'Activado' : 'Desactivado',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isDark
                                      ? Icons.dark_mode
                                      : Icons.light_mode,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ),
                              value: isDark,
                              activeColor: AppColors.accent,
                              onChanged: themeProvider.toggleTheme,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Idioma (Bug #2: marcado como próximamente)
                        const ProfileSectionTitle(title: 'Idioma'),
                        SettingsCard(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _ctrl.selectedLanguage,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.language,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                ),
                                items: ProfileController.languages.entries
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) _ctrl.setLanguage(v);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 56,
                                right: 16,
                                bottom: 12,
                              ),
                              child: Text(
                                'La traducción completa estará disponible próximamente. '
                                'Por ahora se guarda tu preferencia.',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Estilo de viaje (Arq #6: combinado)
                        const ProfileSectionTitle(
                          title: 'Tu estilo de viaje',
                        ),
                        SettingsCard(
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.auto_awesome,
                                color: AppColors.accent,
                              ),
                              title: Text(_ctrl.buildTravelStyle()),
                              subtitle: const Text(
                                'Basado en tus preferencias activas',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Preferencias de viaje
                        const ProfileSectionTitle(
                          title: 'Preferencias de viaje',
                        ),
                        SettingsCard(
                          children: [
                            PrefTile(
                              icon: Icons.forest_outlined,
                              label: 'Naturaleza',
                              value: _ctrl.likesNature,
                              onChanged: _ctrl.setNature,
                            ),
                            const SettingsDivider(),
                            PrefTile(
                              icon: Icons.museum_outlined,
                              label: 'Cultura e historia',
                              value: _ctrl.likesCulture,
                              onChanged: _ctrl.setCulture,
                            ),
                            const SettingsDivider(),
                            PrefTile(
                              icon: Icons.restaurant_outlined,
                              label: 'Gastronomía',
                              value: _ctrl.likesFood,
                              onChanged: _ctrl.setFood,
                            ),
                            const SettingsDivider(),
                            PrefTile(
                              icon: Icons.hiking_outlined,
                              label: 'Aventura',
                              value: _ctrl.likesAdventure,
                              onChanged: _ctrl.setAdventure,
                            ),
                            const SettingsDivider(),
                            PrefTile(
                              icon: Icons.beach_access_outlined,
                              label: 'Playa y relax',
                              value: _ctrl.likesBeach,
                              onChanged: _ctrl.setBeach,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Presupuesto (UX #9: granularidad mejorada)
                        const ProfileSectionTitle(
                          title: 'Presupuesto por noche',
                        ),
                        SettingsCard(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Máximo por noche',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '\$${_ctrl.budget.toInt()} USD',
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Slider(
                              min: 50,
                              max: 3000,
                              // UX #9: Más divisiones para mayor granularidad
                              // Cada step = ~$25 en vez de ~$50
                              divisions: 118,
                              value: _ctrl.budget,
                              activeColor: AppColors.accent,
                              onChanged: _ctrl.setBudget,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$50',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '\$3,000',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Botón guardar preferencias
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: _ctrl.isSavingPrefs
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save_outlined,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              _ctrl.isSavingPrefs
                                  ? 'Guardando...'
                                  : _ctrl.hasUnsavedChanges
                                      ? 'Guardar cambios'
                                      : 'Preferencias guardadas',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _ctrl.hasUnsavedChanges
                                  ? AppColors.accent
                                  : Colors.grey,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: (_ctrl.isSavingPrefs ||
                                    !_ctrl.hasUnsavedChanges)
                                ? null
                                : _handleSavePreferences,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Cuenta
                        const ProfileSectionTitle(title: 'Cuenta'),
                        SettingsCard(
                          children: [
                            ActionTile(
                              icon: Icons.admin_panel_settings_outlined,
                              label: 'Panel de administración',
                              color: Colors.purple,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.admin),
                            ),
                            const SettingsDivider(),
                            ActionTile(
                              icon: Icons.person_outline,
                              label: 'Editar perfil',
                              color: AppColors.accent,
                              onTap: _handleEditProfile,
                            ),
                            const SettingsDivider(),
                            ActionTile(
                              icon: Icons.shield_outlined,
                              label: 'Privacidad y datos',
                              color: AppColors.accent,
                              onTap: () => PrivacyInfoSheet.show(context),
                            ),
                            const SettingsDivider(),
                            ActionTile(
                              icon: Icons.logout,
                              label: 'Cerrar sesión',
                              color: Colors.red,
                              onTap: _signOut,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Versión
                        Center(
                          child: Text(
                            'Aikōra Sora v1.0.0 · Hecho con ❤️ en Cartagena',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
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

  // ── Widgets internos ──

  /// Banner animado que indica cambios pendientes (UX #8).
  Widget _buildUnsavedBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tienes cambios sin guardar',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: _handleSavePreferences,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Header con avatar, nombre, email y badge de miembro.
  SliverAppBar _buildHeader() {
    return SliverAppBar(
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

                // Avatar con botón funcional (Bug #1 fix)
                GestureDetector(
                  onTap: _handleEditAvatar,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withAlpha(102),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.accent.withAlpha(77),
                          backgroundImage: _ctrl.avatarUrl != null
                              ? NetworkImage(_ctrl.avatarUrl!)
                              : null,
                          child: _ctrl.avatarUrl == null
                              ? Text(
                                  _ctrl.initials,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
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
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  _ctrl.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ctrl.email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),

                // Perf #10: memberSince cacheado en el controller
                if (_ctrl.memberSince.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _ctrl.memberSince,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
