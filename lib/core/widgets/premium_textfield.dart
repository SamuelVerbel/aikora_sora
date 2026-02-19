import 'package:flutter/material.dart';

class PremiumTextField extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final ValueChanged<String>? onChanged;

  const PremiumTextField({
    super.key,
    required this.hint,
    this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }
}
