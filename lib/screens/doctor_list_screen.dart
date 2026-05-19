import 'package:flutter/material.dart';

class DoctorListScreen extends StatelessWidget {
  DoctorListScreen({super.key});

  // Liste fictive de médecins
  final List<Map<String, String>> doctors = [
    {'name': 'Dr. Dupont', 'specialty': 'Médecine générale', 'city': 'Lyon'},
    {'name': 'Dr. Martin', 'specialty': 'Dentiste', 'city': 'Lyon'},
    {'name': 'Dr. Bernard', 'specialty': 'Pédiatre', 'city': 'Lyon'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Médecins disponibles')),
      body: ListView.builder(
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return ListTile(
            title: Text(doctor['name']!),
            subtitle: Text('${doctor['specialty']} – ${doctor['city']}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Pour l’instant, on affiche un tutoriel
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rendez‑vous non réel : ${doctor['name']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
