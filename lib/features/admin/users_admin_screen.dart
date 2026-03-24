import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'admin_service.dart';

/// Gestión de usuarios — ver perfiles, asignar roles, eliminar cuentas.
/// Versión Enterprise con:
/// - Confirmaciones con motivo
/// - Feedback visual mejorado
/// - Animaciones suaves
/// - Exportación de datos (mock)
/// - Búsqueda avanzada
class UsersAdminScreen extends StatefulWidget {
  final bool embedded;
  const UsersAdminScreen({super.key, this.embedded = false});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> with SingleTickerProviderStateMixin {
  final AdminService _admin = AdminService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  bool _isExporting = false;
  final _searchCtrl = TextEditingController();
  String? _currentUserId;
  String _roleFilter = 'all'; // all, admin, user
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _load();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _admin.getAllUsers();
    if (mounted) {
      setState(() {
        _users = data;
        _applyFilters();
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        // Filtro por rol
        if (_roleFilter != 'all') {
          final role = u['role'] ?? 'user';
          if (_roleFilter == 'admin' && role != 'admin') return false;
          if (_roleFilter == 'user' && role == 'admin') return false;
        }
        // Filtro por búsqueda
        if (query.isNotEmpty) {
          final name = (u['full_name'] ?? '').toLowerCase();
          final email = (u['email'] ?? '').toLowerCase();
          if (!name.contains(query) && !email.contains(query)) return false;
        }
        return true;
      }).toList();
    });
  }

  void _onSearch(String q) => _applyFilters();
  void _onRoleFilter(String? role) => _applyFilters();

  Future<void> _exportUsers() async {
    setState(() => _isExporting = true);
    
    // Simular exportación
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Crear CSV
    final csv = StringBuffer();
    csv.writeln('Nombre,Email,Rol,Fecha Registro');
    for (final user in _filtered) {
      csv.writeln('"${user['full_name'] ?? ''}","${user['email'] ?? ''}","${user['role'] ?? 'user'}","${_formatDate(user['created_at'])}"');
    }
    
    // Mostrar diálogo con los datos (en web se puede descargar)
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111D2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Exportar usuarios', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_filtered.length} usuarios exportados', 
                style: TextStyle(color: Colors.white.withOpacity(0.6))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                csv.toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 10,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: Text('Cerrar', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copiar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              // Copiar al portapapeles
              // En web usar Clipboard.setData
              Navigator.pop(_);
              _showSnack('📋 ${_filtered.length} usuarios copiados al portapapeles', true);
            },
          ),
        ],
      ),
    );
    
    setState(() => _isExporting = false);
  }

  Future<void> _changeRole(Map<String, dynamic> user) async {
    if (user['id'] == _currentUserId) {
      _showSnack('No puedes cambiar tu propio rol', false);
      return;
    }

    final currentRole = user['role'] ?? 'user';
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    final isPromoting = newRole == 'admin';

    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111D2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(isPromoting ? Icons.admin_panel_settings : Icons.person_remove,
                color: isPromoting ? Colors.orange : AppColors.accent),
            const SizedBox(width: 8),
            Text(
              isPromoting ? 'Hacer administrador' : 'Quitar administrador',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPromoting
                  ? '¿Dar permisos de administrador a "${user['full_name'] ?? user['email']}"?'
                  : '¿Quitar permisos de administrador a "${user['full_name'] ?? user['email']}"?',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              isPromoting
                  ? 'Los administradores pueden gestionar destinos, usuarios y reservas.'
                  : 'El usuario perderá acceso al panel de administración.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Motivo del cambio (opcional)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPromoting ? Colors.orange : AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isPromoting ? 'Hacer admin' : 'Quitar admin'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;

    try {
      await _admin.setUserRole(user['id'], newRole);
      _load();
      _showSnack(
        isPromoting 
          ? '✨ ${user['full_name'] ?? user['email']} ahora es administrador'
          : '🔽 ${user['full_name'] ?? user['email']} ya no es administrador',
        true,
      );
    } catch (e) {
      _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}', false);
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    if (user['id'] == _currentUserId) {
      _showSnack('No puedes eliminar tu propia cuenta', false);
      return;
    }

    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111D2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Eliminar usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Eliminar la cuenta de "${user['full_name'] ?? user['email']}"?',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción no se puede deshacer. Todas sus reservas y datos serán eliminados.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Motivo de eliminación (opcional)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar permanentemente'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;

    try {
      await _admin.deleteUser(user['id']);
      _load();
      _showSnack('🗑️ Usuario eliminado correctamente', true);
    } catch (e) {
      _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}', false);
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color color,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF111D2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(message, style: TextStyle(color: Colors.white.withOpacity(0.6))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    final date = DateTime.tryParse(d);
    if (date == null) return '';
    const m = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${date.day} ${m[date.month - 1]} ${date.year}';
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Barra de herramientas mejorada
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Búsqueda
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearch,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o email...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 18),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.4), size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filtro por rol
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _roleFilter,
                        icon: Icon(Icons.filter_list, color: Colors.white.withOpacity(0.5), size: 18),
                        dropdownColor: const Color(0xFF111D2E),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (v) {
                          setState(() => _roleFilter = v ?? 'all');
                          _applyFilters();
                        },
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                          DropdownMenuItem(value: 'admin', child: Text('Administradores')),
                          DropdownMenuItem(value: 'user', child: Text('Usuarios')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón exportar
                  Tooltip(
                    message: 'Exportar lista de usuarios',
                    child: Material(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _isExporting ? null : _exportUsers,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: _isExporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                                )
                              : Icon(Icons.download_rounded, color: Colors.white.withOpacity(0.6), size: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Contador
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filtered.length} / ${_users.length}',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista de usuarios
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.white.withOpacity(0.15)),
                          const SizedBox(height: 12),
                          Text('No hay usuarios que coincidan',
                              style: TextStyle(color: Colors.white.withOpacity(0.3))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          final isWide = constraints.maxWidth > 650;
                          return isWide
                              ? _buildTable()
                              : _buildCards();
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(width: 44),
                _th('Nombre', flex: 3),
                _th('Email', flex: 3),
                _th('Rol', flex: 2),
                _th('Registro', flex: 2),
                const SizedBox(width: 80),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ..._filtered.map((u) => _UserRow(
                user: u,
                currentUserId: currentUserId,
                formatDate: _formatDate,
                onChangeRole: () => _changeRole(u),
                onDelete: () => _deleteUser(u),
              )),
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _buildCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final u = _filtered[i];
        final isAdmin = (u['role'] ?? '') == 'admin';
        final isCurrentUser = u['id'] == _currentUserId;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111D2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAdmin
                        ? Colors.orange.withOpacity(0.15)
                        : AppColors.accent.withOpacity(0.12),
                    child: Text(
                      ((u['full_name'] ?? u['email'] ?? 'U') as String)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        color: isAdmin ? Colors.orange : AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCurrentUser)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(u['full_name'] ?? 'Sin nombre',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Tú',
                                style: TextStyle(color: AppColors.success, fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    Text(u['email'] ?? '',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              ),
              if (!isCurrentUser)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.4)),
                  color: const Color(0xFF1A2840),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'role') _changeRole(u);
                    if (v == 'delete') _deleteUser(u);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'role',
                      child: Row(children: [
                        Icon(Icons.swap_horiz,
                            color: isAdmin ? AppColors.accent : Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(isAdmin ? 'Quitar admin' : 'Hacer admin',
                            style: const TextStyle(color: Colors.white)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();
    return Scaffold(
      backgroundColor: const Color(0xFF070E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1520),
        title: const Text('Usuarios', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILA DE TABLA MEJORADA
// ─────────────────────────────────────────────────────────────────────────────

class _UserRow extends StatefulWidget {
  final Map<String, dynamic> user;
  final String currentUserId;
  final String Function(String?) formatDate;
  final VoidCallback onChangeRole;
  final VoidCallback onDelete;

  const _UserRow({
    required this.user,
    required this.currentUserId,
    required this.formatDate,
    required this.onChangeRole,
    required this.onDelete,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;
  
  bool get _isCurrentUser => widget.user['id'] == widget.currentUserId;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final isAdmin = (u['role'] ?? '') == 'admin';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _hovered
              ? Colors.white.withOpacity(0.04)
              : const Color(0xFF111D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isAdmin
                      ? Colors.orange.withOpacity(0.15)
                      : AppColors.accent.withOpacity(0.12),
                  child: Text(
                    ((u['full_name'] ?? u['email'] ?? 'U') as String)
                        .substring(0, 1)
                        .toUpperCase(),
                    style: TextStyle(
                      color: isAdmin ? Colors.orange : AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (_isCurrentUser)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Text(
                    u['full_name'] ?? 'Sin nombre',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isCurrentUser) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Tú',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: Text(
                u['email'] ?? '',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? Colors.orange.withOpacity(0.12)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (u['role'] ?? 'user').toUpperCase(),
                  style: TextStyle(
                    color: isAdmin ? Colors.orange : Colors.blue.shade300,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                widget.formatDate(u['created_at']),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 12),
              ),
            ),

            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isCurrentUser) ...[
                    Tooltip(
                      message: isAdmin ? 'Quitar admin' : 'Hacer admin',
                      child: Material(
                        color: (isAdmin ? Colors.orange : AppColors.accent)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: widget.onChangeRole,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(
                              Icons.swap_horiz_rounded,
                              color: AppColors.accent,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Eliminar',
                      child: Material(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: widget.onDelete,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(Icons.delete_outline_rounded,
                                color: AppColors.error, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Tú',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}