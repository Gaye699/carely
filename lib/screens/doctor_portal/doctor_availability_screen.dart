import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

const _dayNames = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

class _Slot {
  final int dayOfWeek;
  int startHour;
  int endHour;

  _Slot({required this.dayOfWeek, required this.startHour, required this.endHour});

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startHour': startHour,
        'endHour': endHour,
      };
}

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final List<_Slot> _slots = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final headers = await auth.getAuthHeaders();
    try {
      final res = await http
          .get(Uri.parse('${AuthService.baseUrl}/doctor/availability'), headers: headers)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _slots.clear();
          _slots.addAll(list.map((e) => _Slot(
                dayOfWeek: e['dayOfWeek'] as int,
                startHour: e['startHour'] as int,
                endHour: e['endHour'] as int,
              )));
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    final headers = await auth.getAuthHeaders();
    try {
      final res = await http
          .post(
            Uri.parse('${AuthService.baseUrl}/doctor/availability'),
            headers: headers,
            body: jsonEncode({'slots': _slots.map((s) => s.toJson()).toList()}),
          )
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() => _saving = false);
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horaires enregistrés'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addSlot(int day) {
    setState(() {
      _slots.add(_Slot(dayOfWeek: day, startHour: 9, endHour: 12));
    });
  }

  void _removeSlot(int index) {
    setState(() => _slots.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes horaires'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Définissez vos plages horaires hebdomadaires. '
                            'Les créneaux de 30 min seront automatiquement générés pour les patients.',
                            style: TextStyle(color: AppColors.primary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pour chaque jour 1-7
                  for (int day = 1; day <= 7; day++) ...[
                    _daySection(day, isDark, theme),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _daySection(int day, bool isDark, ThemeData theme) {
    final daySlots = _slots
        .asMap()
        .entries
        .where((e) => e.value.dayOfWeek == day)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  _dayNames[day],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addSlot(day),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                  label: const Text('Ajouter',
                      style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          if (daySlots.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 14),
              child: Text(
                'Pas disponible',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
          for (final entry in daySlots)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _slotRow(entry.key, entry.value, isDark),
            ),
        ],
      ),
    );
  }

  Widget _slotRow(int index, _Slot slot, bool isDark) {
    return Row(
      children: [
        const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        _hourPicker('De', slot.startHour, (v) {
          setState(() => slot.startHour = v);
        }, isDark),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('→'),
        ),
        _hourPicker('À', slot.endHour, (v) {
          setState(() => slot.endHour = v);
        }, isDark),
        const Spacer(),
        IconButton(
          onPressed: () => _removeSlot(index),
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _hourPicker(String label, int value, ValueChanged<int> onChanged, bool isDark) {
    return DropdownButton<int>(
      value: value,
      underline: const SizedBox.shrink(),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      items: List.generate(16, (i) => i + 6)
          .map((h) => DropdownMenuItem(value: h, child: Text('${h}h00')))
          .toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
