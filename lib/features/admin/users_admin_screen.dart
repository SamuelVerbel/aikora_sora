// ═════════════════════════════════════════════════════════════════════════════
// users_admin_screen.dart
// ═════════════════════════════════════════════════════════════════════════════
// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'admin_service.dart';

/// Gestión de usuarios — ver perfiles, asignar roles, eliminar cuentas.
class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  final AdminService _admin = AdminService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _admin.getAllUsers();
    if (mounted) {
      setState(() {
        _users = data;
        _filtered = data;
        _isLoading = false;
      });
    }
  }

  void _onSearch(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = _users.where((u) =>
        (u['full_name'] ?? '').toLowerCase().contains(query) ||
        (u['email'] ?? '').toLowerCase().contains(query)
      ).toList();
    });
  }

  Future<void> _changeRole(Map<String, dynamic> user) async {
    final currentRole = user['role'] ?? 'user';
    final newRole = currentRole == 'admin' ? 'user' : 'admin';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cambiar rol'),
        content: Text(
          '¿Cambiar el rol de "${user['full_name'] ?? user['email']}" '
          'de $currentRole a $newRole?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newRole == 'admin' ? Colors.orange : AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cambiar a $newRole'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _admin.setUserRole(user['id'], newRole);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol actualizado a $newRole'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar la cuenta de "${user['full_name'] ?? user['email']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _admin.deleteUser(user['id']);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No hay usuarios'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final u = _filtered[i];
                            final role = u['role'] ?? 'user';
                            final isAdmin = role == 'admin';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                leading: CircleAvatar(
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
                                title: Text(
                                  u['full_name'] ?? 'Sin nombre',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u['email'] ?? '',
                                        style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? Colors.orange.withOpacity(0.12)
                                            : Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: TextStyle(
                                          color: isAdmin ? Colors.orange : Colors.blue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (action) {
                                    if (action == 'role') _changeRole(u);
                                    if (action == 'delete') _deleteUser(u);
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'role',
                                      child: Row(children: [
                                        Icon(Icons.swap_horiz,
                                            color: isAdmin ? AppColors.accent : Colors.orange,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Text(isAdmin
                                            ? 'Quitar admin'
                                            : 'Hacer admin'),
                                      ]),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        Icon(Icons.delete_outline,
                                            color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Text('Eliminar',
                                            style: TextStyle(color: Colors.red)),
                                      ]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}