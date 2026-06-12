import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/consultant_provider.dart';
import '../core/theme/app_colors.dart';

class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Médecins disponibles')),
      body: Consumer<ConsultantProvider>(
        builder: (_, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (provider.allConsultants.isEmpty) {
            return const Center(child: Text('Aucun médecin trouvé'));
          }
          return ListView.separated(
            itemCount: provider.allConsultants.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = provider.allConsultants[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary),
                ),
                title: Text(c.fullName),
                subtitle: Text(c.specialty),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Médecin sélectionné : ${c.fullName}')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
