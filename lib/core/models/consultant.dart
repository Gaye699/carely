import 'package:flutter/material.dart';

class ConsultantDomain {
  ConsultantDomain._();

  static const String general = 'general';
  static const String cardiology = 'cardiology';
  static const String dermatology = 'dermatology';
  static const String neurology = 'neurology';
  static const String pediatrics = 'pediatrics';
  static const String orthopedics = 'orthopedics';
  static const String ophthalmology = 'ophthalmology';
  static const String psychiatry = 'psychiatry';
  static const String dental = 'dental';
  static const String gynecology = 'gynecology';

  static const List<String> all = [
    general,
    cardiology,
    dermatology,
    neurology,
    pediatrics,
    orthopedics,
    ophthalmology,
    psychiatry,
    dental,
    gynecology,
  ];

  static const Map<String, String> labels = {
    general: 'Médecine générale',
    cardiology: 'Cardiologie',
    dermatology: 'Dermatologie',
    neurology: 'Neurologie',
    pediatrics: 'Pédiatrie',
    orthopedics: 'Orthopédie',
    ophthalmology: 'Ophtalmologie',
    psychiatry: 'Psychiatrie',
    dental: 'Dentiste',
    gynecology: 'Gynécologie',
  };

  static const Map<String, String> shortLabels = {
    general: 'Généraliste',
    cardiology: 'Cardio',
    dermatology: 'Dermato',
    neurology: 'Neuro',
    pediatrics: 'Pédiatre',
    orthopedics: 'Ortho',
    ophthalmology: 'Ophtalmo',
    psychiatry: 'Psy',
    dental: 'Dentiste',
    gynecology: 'Gynéco',
  };

  static const Map<String, IconData> icons = {
    general: Icons.local_hospital_rounded,
    cardiology: Icons.favorite_rounded,
    dermatology: Icons.face_rounded,
    neurology: Icons.psychology_rounded,
    pediatrics: Icons.child_care_rounded,
    orthopedics: Icons.accessibility_new_rounded,
    ophthalmology: Icons.visibility_rounded,
    psychiatry: Icons.self_improvement_rounded,
    dental: Icons.medical_services_rounded,
    gynecology: Icons.pregnant_woman_rounded,
  };

  static String label(String domain) => labels[domain] ?? domain;
  static String shortLabel(String domain) => shortLabels[domain] ?? labels[domain] ?? domain;
  static IconData icon(String domain) => icons[domain] ?? Icons.local_hospital_rounded;

  static String fromSpecialty(String specialty) {
    final s = specialty.toLowerCase();
    if (s.contains('généraliste') || s.contains('generaliste') || s.contains('général')) return general;
    if (s.contains('cardio')) return cardiology;
    if (s.contains('dermato')) return dermatology;
    if (s.contains('neuro')) return neurology;
    if (s.contains('pédiat') || s.contains('pediat')) return pediatrics;
    if (s.contains('orthop')) return orthopedics;
    if (s.contains('ophtalmo') || s.contains('ophthal')) return ophthalmology;
    if (s.contains('psychiatr') || s.contains('psy')) return psychiatry;
    if (s.contains('dentiste') || s.contains('dentist')) return dental;
    if (s.contains('gynéco') || s.contains('gyneco')) return gynecology;
    return general;
  }
}

class Consultant {
  final int? id;
  final String fullName;
  final String specialty;
  final String domain;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final double rating;
  final bool available;
  final String? createdAt;
  final String? updatedAt;

  const Consultant({
    this.id,
    required this.fullName,
    required this.specialty,
    required this.domain,
    this.email,
    this.phone,
    this.photoUrl,
    this.rating = 0.0,
    this.available = true,
    this.createdAt,
    this.updatedAt,
  });

  // From local SQLite
  factory Consultant.fromMap(Map<String, dynamic> map) => Consultant(
        id: map['id'] as int?,
        fullName: map['full_name'] as String,
        specialty: map['specialty'] as String,
        domain: map['domain'] as String,
        email: map['email'] as String?,
        phone: map['phone'] as String?,
        photoUrl: map['photo_url'] as String?,
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        available: (map['available'] as int?) == 1,
        createdAt: map['created_at'] as String?,
        updatedAt: map['updated_at'] as String?,
      );

  // From backend API (admin-managed doctors)
  factory Consultant.fromApiMap(Map<String, dynamic> map) {
    final firstName = map['firstName'] as String? ?? '';
    final lastName = map['lastName'] as String? ?? '';
    final specialty = map['specialty'] as String? ?? '';
    final isActive = map['isActive'];

    return Consultant(
      id: map['id'] as int?,
      fullName: 'Dr. $firstName $lastName'.trim(),
      specialty: specialty,
      domain: ConsultantDomain.fromSpecialty(specialty),
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      available: isActive == null || isActive == 1 || isActive == true,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'full_name': fullName,
        'specialty': specialty,
        'domain': domain,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photo_url': photoUrl,
        'rating': rating,
        'available': available ? 1 : 0,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}
