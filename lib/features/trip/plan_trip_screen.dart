import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PlanTripScreen extends StatefulWidget {
  const PlanTripScreen({super.key});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _typeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Planear viaje con IA"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Diseña tu próximo viaje ✨",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Cuéntanos tus ideas y nuestra IA creará un plan personalizado para ti.",
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 30),

              _buildCardInput(
                label: "Destino",
                hint: "Ej: París, Cartagena, Tokio",
                icon: Icons.place,
                controller: _destinationController,
              ),

              const SizedBox(height: 20),

              _buildCardInput(
                label: "Presupuesto aproximado",
                hint: "Ej: 2.000.000 COP",
                icon: Icons.attach_money,
                controller: _budgetController,
              ),

              const SizedBox(height: 20),

              _buildCardInput(
                label: "Tipo de viaje",
                hint: "Ej: Aventura, relajado, cultural",
                icon: Icons.explore,
                controller: _typeController,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    "Generar plan con IA",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    _generatePlan();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            icon: Icon(icon, color: AppColors.accent),
            labelText: label,
            hintText: hint,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  void _generatePlan() {
    if (_destinationController.text.isEmpty ||
        _budgetController.text.isEmpty ||
        _typeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Completa todos los campos"),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/plan-result',
      arguments: {
        'destination': _destinationController.text,
        'budget': _budgetController.text,
        'type': _typeController.text,
      },
    );
  }
}