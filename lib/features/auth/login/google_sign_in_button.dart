// lib/features/auth/login/google_sign_in_button.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.signInWithGoogle();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error al iniciar con Google: ${e.toString().replaceAll('Exception: ', '')}'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : Colors.grey[800],
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300]!,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // TU ÍCONO DE GOOGLE ORIGINAL
                  Image.asset(
                    'assets/icons/google.png',
                    height: 20,
                    width: 20,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continuar con Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}