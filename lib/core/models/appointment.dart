class Appointment {
  final int id;
  final int doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String date;
  final String time;
  final String status;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.date,
    required this.time,
    required this.status,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    String doctorName;
    String doctorSpecialty;

    if (map['doctor'] is Map) {
      final d = map['doctor'] as Map<String, dynamic>;
      doctorName = 'Dr. ${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
      doctorSpecialty = d['specialty'] as String? ?? '';
    } else {
      final raw = map['doctorName'] as String? ?? '';
      doctorName = raw.startsWith('Dr.') ? raw : 'Dr. $raw';
      doctorSpecialty = map['doctorSpecialty'] as String? ?? map['specialty'] as String? ?? '';
    }

    // Le backend renvoie "dateTime" au format ISO "2024-06-17T09:00"
    final rawDt = map['dateTime'] as String? ?? map['date'] as String? ?? '';
    final date = rawDt.length >= 10 ? rawDt.substring(0, 10) : rawDt;
    final time = rawDt.length >= 16 ? rawDt.substring(11, 16) : (map['time'] as String? ?? '');

    return Appointment(
      id: (map['id'] as num).toInt(),
      doctorId: ((map['doctorId'] ?? map['doctor_id']) as num? ?? 0).toInt(),
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      date: date,
      time: time,
      status: map['status'] as String? ?? 'confirmed',
    );
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'À venir';
    }
  }
}
