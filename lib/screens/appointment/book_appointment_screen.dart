import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookAppointmentScreen extends StatelessWidget {
  final String doctorId;
  const BookAppointmentScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Prendre rendez-vous'),
      ),
      body: const Center(child: Text('Booking — à implémenter')),
    );
  }
}
