import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.login),
        label: const Text('Continuar con Google'),
        onPressed: () => auth.signInWithGoogle(),
      ),
    );
  }
}