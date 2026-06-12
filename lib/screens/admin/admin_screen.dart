import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Administration'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Médecins'),
              Tab(text: 'Statistiques'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _AddDoctorForm(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un médecin'),
          backgroundColor: AppColors.primary,
        ),
        body: const TabBarView(children: [_DoctorsList(), _StatsTab()]),
      ),
    );
  }
}

// ── Liste médecins ────────────────────────────────────────────────────────────
class _DoctorsList extends StatefulWidget {
  const _DoctorsList();
  @override
  State<_DoctorsList> createState() => _DoctorsListState();
}

class _DoctorsListState extends State<_DoctorsList> {
  List<dynamic> _doctors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final headers = await context.read<AuthService>().getAuthHeaders();
    final url = '${AuthService.baseUrl}/doctors';
    final res = await http.get(Uri.parse(url), headers: headers);
    if (res.statusCode == 200 && mounted) {
      setState(() {
        _doctors = jsonDecode(res.body);
        _loading = false;
      });
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Désactiver ce médecin ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final headers = await context.read<AuthService>().getAuthHeaders();
      await http.delete(
        Uri.parse('${AuthService.baseUrl}/admin/doctors/$id'),
        headers: headers,
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _doctors.length,
        itemBuilder: (_, i) {
          final d = _doctors[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  d['lastName'][0],
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text('Dr. ${d['firstName']} ${d['lastName']}'),
              subtitle: Text(d['specialty']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today, size: 20),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _AddSlotsForm(doctorId: d['id']),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _delete(d['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Formulaire ajout médecin ──────────────────────────────────────────────────
class _AddDoctorForm extends StatefulWidget {
  const _AddDoctorForm();
  @override
  State<_AddDoctorForm> createState() => _AddDoctorFormState();
}

class _AddDoctorFormState extends State<_AddDoctorForm> {
  final _key = GlobalKey<FormState>();
  final _fn = TextEditingController(),
      _ln = TextEditingController(),
      _city = TextEditingController(),
      _addr = TextEditingController(),
      _phone = TextEditingController(),
      _price = TextEditingController(),
      _desc = TextEditingController();
  String _specialty = 'Généraliste';
  bool _loading = false;

  static const _specialties = [
    'Généraliste',
    'Cardiologue',
    'Dentiste',
    'Ophtalmologue',
    'Neurologue',
    'Orthopédiste',
    'Pédiatre',
  ];

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _loading = true);
    final headers = await context.read<AuthService>().getAuthHeaders();
    final res = await http.post(
      Uri.parse('${AuthService.baseUrl}/admin/doctors'),
      headers: headers,
      body: jsonEncode({
        'firstName': _fn.text.trim(),
        'lastName': _ln.text.trim(),
        'specialty': _specialty,
        'description': _desc.text.trim(),
        'city': _city.text.trim(),
        'address': _addr.text.trim(),
        'phone': _phone.text.trim(),
        'price': double.tryParse(_price.text) ?? 0,
      }),
    );
    if (res.statusCode == 201 && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Médecin ajouté')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheet(
      title: 'Ajouter un médecin',
      child: Form(
        key: _key,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _Field('Prénom', _fn)),
                const SizedBox(width: 12),
                Expanded(child: _Field('Nom', _ln)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _specialty,
              decoration: const InputDecoration(labelText: 'Spécialité'),
              items: _specialties
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _specialty = v!),
            ),
            const SizedBox(height: 16),
            _Field('Ville', _city),
            const SizedBox(height: 16),
            _Field('Adresse', _addr, required: false),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    'Téléphone',
                    _phone,
                    required: false,
                    type: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    'Tarif (€)',
                    _price,
                    required: false,
                    type: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formulaire ajout créneaux ─────────────────────────────────────────────────
class _AddSlotsForm extends StatefulWidget {
  final int doctorId;
  const _AddSlotsForm({required this.doctorId});
  @override
  State<_AddSlotsForm> createState() => _AddSlotsFormState();
}

class _AddSlotsFormState extends State<_AddSlotsForm> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  final List<String> _times = [];
  bool _loading = false;

  static const _options = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
  ];

  Future<void> _submit() async {
    if (_times.isEmpty) return;
    setState(() => _loading = true);
    final dateStr = _date.toIso8601String().split('T')[0];
    final slots = _times.map((t) => '${dateStr}T$t:00').toList();
    final headers = await context.read<AuthService>().getAuthHeaders();
    await http.post(
      Uri.parse(
        '${AuthService.baseUrl}/admin/doctors/${widget.doctorId}/slots',
      ),
      headers: headers,
      body: jsonEncode({'slots': slots}),
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${slots.length} créneaux ajoutés')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheet(
      title: 'Ajouter des créneaux',
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_today, color: AppColors.primary),
            title: Text('${_date.day}/${_date.month}/${_date.year}'),
            trailing: TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (d != null) setState(() => _date = d);
              },
              child: const Text('Changer'),
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Créneaux',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options
                .map(
                  (t) => FilterChip(
                    label: Text(t),
                    selected: _times.contains(t),
                    onSelected: (v) =>
                        setState(() => v ? _times.add(t) : _times.remove(t)),
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primary,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_loading || _times.isEmpty) ? null : _submit,
            child: Text('Ajouter ${_times.length} créneau(x)'),
          ),
        ],
      ),
    );
  }
}

// ── Statistiques ──────────────────────────────────────────────────────────────
class _StatsTab extends StatefulWidget {
  const _StatsTab();
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final headers = await context.read<AuthService>().getAuthHeaders();
    final res = await http.get(
      Uri.parse('${AuthService.baseUrl}/admin/stats'),
      headers: headers,
    );
    if (res.statusCode == 200 && mounted)
      setState(() => _stats = jsonDecode(res.body));
  }

  @override
  Widget build(BuildContext context) {
    if (_stats == null) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: [
          _StatCard(
            'Médecins',
            _stats!['totalDoctors'],
            Icons.local_hospital,
            AppColors.primary,
          ),
          _StatCard(
            'Patients',
            _stats!['totalPatients'],
            Icons.people,
            AppColors.success,
          ),
          _StatCard(
            'RDV Total',
            _stats!['totalAppointments'],
            Icons.calendar_month,
            AppColors.warning,
          ),
          _StatCard(
            "Aujourd'hui",
            _stats!['todayAppointments'],
            Icons.today,
            AppColors.navy,
          ),
        ],
      ),
    );
  }
}

// ── Widgets partagés ──────────────────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _BottomSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool required;
  final TextInputType type;
  const _Field(
    this.label,
    this.ctrl, {
    this.required = true,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: type,
    decoration: InputDecoration(labelText: label),
    validator: required ? (v) => v!.trim().isEmpty ? 'Requis' : null : null,
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: AppColors.grey700, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
