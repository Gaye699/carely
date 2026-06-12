import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorDetailScreen extends StatelessWidget {
  final String doctorId;
  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Fiche médecin'),
      ),
      body: Center(child: Text('Médecin ID: $doctorId — à implémenter')),
    );
  }
}
