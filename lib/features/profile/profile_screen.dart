import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../auth/services/preferences_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = Supabase.instance.client.auth.currentUser;

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
    final userName = user?.email?.split('@').first ?? "Viajero";
    final email = user?.email ?? "correo@ejemplo.com";

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // 👤 Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.accent.withOpacity(0.2),
                child: Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                email,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                label: const Text("Editar perfil"),
              ),

              const SizedBox(height: 40),

              _sectionTitle("Preferencias de viaje"),

              const SizedBox(height: 16),

              _preferenceSwitch(
                "Naturaleza",
                likesNature,
                (v) => setState(() => likesNature = v),
              ),

              _preferenceSwitch(
                "Cultura",
                likesCulture,
                (v) => setState(() => likesCulture = v),
              ),

              _preferenceSwitch(
                "Gastronomía",
                likesFood,
                (v) => setState(() => likesFood = v),
              ),

              const SizedBox(height: 30),

              _sectionTitle("Idioma"),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<String>(
                  value: selectedLanguage,
                  isExpanded: true,
                  underline: const SizedBox(),
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
              ),

              const SizedBox(height: 30),

              _sectionTitle("Presupuesto aproximado"),

              const SizedBox(height: 10),

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

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
                        content: Text("Preferencias guardadas"),
                      ),
                    );
                  },
                  child: const Text("Guardar cambios"),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _preferenceSwitch(
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title),
        value: value,
        activeColor: AppColors.accent,
        onChanged: onChanged,
      ),
    );
  }
}