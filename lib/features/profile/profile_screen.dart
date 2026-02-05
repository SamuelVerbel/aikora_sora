import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'services/preferences_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool likesNature = true;
  bool likesCulture = false;
  bool likesFood = true;

  String selectedLanguage = 'es';
  double budget = 500;

  final Map<String, String> languages = {
  'es': 'Español',
  'en': 'English',
  'pt': 'Português',
  'fr': 'Français',
  'de': 'Deutsch',
  'it': 'Italiano',
  'ja': '日本語',
  'ko': '한국어',
};

  @override
    void initState() {
      super.initState();
      _loadPreferences();
    }

    Future<void> _loadPreferences() async {
      final data = await PreferencesService.loadPreferences();

      setState(() {
        likesNature = data['nature'];
        likesCulture = data['culture'];
        likesFood = data['food'];
        selectedLanguage = data['language'];
        budget = data['budget'];
      });
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferencias',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Naturaleza'),
              value: likesNature,
              onChanged: (value) {
                setState(() => likesNature = value);
              },
            ),
            SwitchListTile(
              title: const Text('Cultura'),
              value: likesCulture,
              onChanged: (value) {
                setState(() => likesCulture = value);
              },
            ),
            SwitchListTile(
              title: const Text('Gastronomía'),
              value: likesFood,
              onChanged: (value) {
                setState(() => likesFood = value);
              },
            ),

            const SizedBox(height: 24),
            const Text(
              'Idioma',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            DropdownButton<String>(
              value: selectedLanguage,
              isExpanded: true,
              items: languages.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedLanguage = value!);
              },
            ),

            const SizedBox(height: 24),
            const Text(
              'Presupuesto aproximado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Slider(
              min: 100,
              max: 2000,
              divisions: 19,
              label: '\$${budget.toInt()}',
              value: budget,
              activeColor: AppColors.accent,
              onChanged: (value) {
                setState(() => budget = value);
              },
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () async {
                await PreferencesService.savePreferences(
                  nature: likesNature,
                  culture: likesCulture,
                  food: likesFood,
                  language: selectedLanguage,
                  budget: budget,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preferencias guardadas'),
                  ),
                );
              },
              child: const Text('Guardar preferencias'),
            ),
          ],
        ),
      ),
    );
  }
}
