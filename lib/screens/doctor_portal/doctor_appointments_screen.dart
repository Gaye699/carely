import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<dynamic> _today = [];
  List<dynamic> _upcoming = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final headers = await auth.getAuthHeaders();
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${AuthService.baseUrl}/doctor/appointments?filter=today'),
            headers: headers),
        http.get(Uri.parse('${AuthService.baseUrl}/doctor/appointments?filter=upcoming'),
            headers: headers),
      ]);
      if (!mounted) return;
      setState(() {
        if (results[0].statusCode == 200) _today = jsonDecode(results[0].body) as List;
        if (results[1].statusCode == 200) _upcoming = jsonDecode(results[1].body) as List;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Aujourd'hui"),
            Tab(text: 'À venir'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _list(_today, isDark),
                  _list(_upcoming, isDark),
                ],
              ),
            ),
    );
  }

  Widget _list(List<dynamic> items, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 48,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(height: 12),
            Text('Aucun rendez-vous',
                style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _card(items[i], isDark),
    );
  }

  Widget _card(Map<String, dynamic> appt, bool isDark) {
    final dt = appt['dateTime'] as String? ?? '';
    final date = dt.length >= 10 ? dt.substring(0, 10) : dt;
    final hour = dt.length >= 16 ? dt.substring(11, 16) : '';
    final patient =
        '${appt['patientFirstName'] ?? ''} ${appt['patientLastName'] ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(hour,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(date.length >= 10 ? date.substring(5) : date,
                    style: const TextStyle(color: AppColors.primary, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight)),
                if (appt['reason'] != null && appt['reason'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(appt['reason'].toString(),
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight)),
                  ),
                if (appt['patientPhone'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(appt['patientPhone'].toString(),
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
