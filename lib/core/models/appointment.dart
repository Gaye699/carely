class Appointment {
  final int id;
  final int doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String date;
  final String time;
  final String status; // 'scheduled' | 'completed' | 'cancelled'

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
      final fn = d['firstName'] as String? ?? '';
      final ln = d['lastName'] as String? ?? '';
      doctorName = 'Dr. $fn $ln'.trim();
      doctorSpecialty = d['specialty'] as String? ?? '';
    } else {
      final fn = map['doctorFirstName'] as String? ??
          map['firstName'] as String? ?? '';
      final ln = map['doctorLastName'] as String? ??
          map['lastName'] as String? ?? '';
      doctorName = 'Dr. $fn $ln'.trim();
      doctorSpecialty = map['doctorSpecialty'] as String? ??
          map['specialty'] as String? ?? '';
    }

    return Appointment(
      id: map['id'] as int,
      doctorId: (map['doctorId'] ?? map['doctor_id']) as int,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      date: map['date'] as String? ?? '',
      time: map['time'] as String? ?? '',
      status: map['status'] as String? ?? 'scheduled',
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
