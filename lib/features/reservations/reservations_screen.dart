import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Reservas"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Tus reservas activas ✈️",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: const [
                  ReservationCard(
                    destination: "Tokio",
                    date: "12 - 18 Marzo 2026",
                    status: "Confirmada",
                  ),
                  ReservationCard(
                    destination: "París",
                    date: "5 - 10 Abril 2026",
                    status: "Pendiente",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReservationCard extends StatelessWidget {
  final String destination;
  final String date;
  final String status;

  const ReservationCard({
    super.key,
    required this.destination,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        status == "Confirmada" ? Colors.green : Colors.orange;

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
              destination,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              date,
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}