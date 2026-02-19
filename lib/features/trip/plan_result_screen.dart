import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PlanResultScreen extends StatelessWidget {
  final String destination;
  final String budget;
  final String type;

  const PlanResultScreen({
    super.key,
    required this.destination,
    required this.budget,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tu plan personalizado ✨"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Viaje a $destination",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Presupuesto estimado: $budget",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 6),

            Text(
              "Estilo: $type",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 30),

            const Text(
              "Itinerario sugerido por IA",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            _dayCard(
              day: "Día 1",
              title: "Exploración cultural",
              description:
                  "Recorrido por el centro histórico, museos principales y gastronomía local.",
            ),

            _dayCard(
              day: "Día 2",
              title: "Experiencia local",
              description:
                  "Visita a barrios tradicionales y actividades auténticas recomendadas.",
            ),

            _dayCard(
              day: "Día 3",
              title: "Relajación y naturaleza",
              description:
                  "Tiempo libre en zonas naturales o playas con experiencias personalizadas.",
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bookmark_border),
                label: const Text("Guardar plan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Plan guardado exitosamente"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCard({
    required String day,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(description),
          ],
        ),
      ),
    );
  }
}