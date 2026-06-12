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

  static String label(String domain) => labels[domain] ?? domain;
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
