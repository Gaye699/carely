import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static const _version = 2;
  static Database? _db;

  static Future<void> init() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  static Future<Database> get database async {
    return _db ??= await _open();
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'carely.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: (db, _, _) async {
        await db.execute('DROP TABLE IF EXISTS consultants');
        await _onCreate(db, _version);
      },
    );
  }

  static Future<void> _onCreate(Database db, int _) async {
    await db.execute('''
      CREATE TABLE consultants (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name   TEXT NOT NULL,
        specialty   TEXT NOT NULL,
        domain      TEXT NOT NULL,
        email       TEXT,
        phone       TEXT,
        photo_url   TEXT,
        rating      REAL    DEFAULT 0.0,
        available   INTEGER DEFAULT 1,
        created_at  TEXT,
        updated_at  TEXT
      )
    ''');
    await _seed(db);
  }

  static Future<void> _seed(Database db) async {
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final row in _seedData) {
      batch.insert('consultants', {...row, 'created_at': now, 'updated_at': now});
    }
    await batch.commit(noResult: true);
  }

  // 30 entries across all 10 domains — varied ratings & availability
  static const _seedData = [
    // ── Médecine générale (5) ──────────────────────────────────────────
    {
      'full_name': 'Dr. Sophie Martin',
      'specialty': 'Médecin généraliste',
      'domain': 'general',
      'email': 'sophie.martin@carely.fr',
      'phone': '+33 6 12 34 56 78',
      'photo_url': 'https://i.pravatar.cc/150?img=47',
      'rating': 4.8,
      'available': 1,
    },
    {
      'full_name': 'Dr. Claire Fontaine',
      'specialty': 'Médecin généraliste',
      'domain': 'general',
      'email': 'claire.fontaine@carely.fr',
      'phone': '+33 6 55 66 77 88',
      'photo_url': 'https://i.pravatar.cc/150?img=53',
      'rating': 4.7,
      'available': 1,
    },
    {
      'full_name': 'Dr. Antoine Moreau',
      'specialty': 'Médecin généraliste',
      'domain': 'general',
      'email': 'antoine.moreau@carely.fr',
      'phone': '+33 6 01 11 22 33',
      'photo_url': 'https://i.pravatar.cc/150?img=1',
      'rating': 4.6,
      'available': 1,
    },
    {
      'full_name': 'Dr. Marie-Louise Dubois',
      'specialty': 'Médecin généraliste',
      'domain': 'general',
      'email': 'ml.dubois@carely.fr',
      'phone': '+33 6 02 22 33 44',
      'photo_url': 'https://i.pravatar.cc/150?img=2',
      'rating': 4.5,
      'available': 0,
    },
    {
      'full_name': 'Dr. Henri Leclerc',
      'specialty': 'Médecin généraliste',
      'domain': 'general',
      'email': 'henri.leclerc@carely.fr',
      'phone': '+33 6 03 33 44 55',
      'photo_url': 'https://i.pravatar.cc/150?img=3',
      'rating': 4.3,
      'available': 1,
    },
    // ── Cardiologie (4) ───────────────────────────────────────────────
    {
      'full_name': 'Dr. Thomas Dupont',
      'specialty': 'Cardiologue',
      'domain': 'cardiology',
      'email': 'thomas.dupont@carely.fr',
      'phone': '+33 6 23 45 67 89',
      'photo_url': 'https://i.pravatar.cc/150?img=11',
      'rating': 4.9,
      'available': 1,
    },
    {
      'full_name': 'Dr. Ali Hassan',
      'specialty': 'Cardiologue',
      'domain': 'cardiology',
      'email': 'ali.hassan@carely.fr',
      'phone': '+33 6 11 22 33 44',
      'photo_url': 'https://i.pravatar.cc/150?img=52',
      'rating': 4.4,
      'available': 1,
    },
    {
      'full_name': 'Dr. Céline Marchetti',
      'specialty': 'Cardiologue',
      'domain': 'cardiology',
      'email': 'celine.marchetti@carely.fr',
      'phone': '+33 6 04 44 55 66',
      'photo_url': 'https://i.pravatar.cc/150?img=4',
      'rating': 4.7,
      'available': 1,
    },
    {
      'full_name': 'Dr. Youssef Tahir',
      'specialty': 'Cardiologue',
      'domain': 'cardiology',
      'email': 'youssef.tahir@carely.fr',
      'phone': '+33 6 05 55 66 77',
      'photo_url': 'https://i.pravatar.cc/150?img=5',
      'rating': 4.6,
      'available': 1,
    },
    // ── Dermatologie (3) ──────────────────────────────────────────────
    {
      'full_name': 'Dr. Amina Sow',
      'specialty': 'Dermatologue',
      'domain': 'dermatology',
      'email': 'amina.sow@carely.fr',
      'phone': '+33 6 34 56 78 90',
      'photo_url': 'https://i.pravatar.cc/150?img=48',
      'rating': 4.7,
      'available': 1,
    },
    {
      'full_name': 'Dr. François Lambert',
      'specialty': 'Dermatologue',
      'domain': 'dermatology',
      'email': 'francois.lambert@carely.fr',
      'phone': '+33 6 06 66 77 88',
      'photo_url': 'https://i.pravatar.cc/150?img=6',
      'rating': 4.5,
      'available': 1,
    },
    {
      'full_name': 'Dr. Elena Petrov',
      'specialty': 'Dermatologue',
      'domain': 'dermatology',
      'email': 'elena.petrov@carely.fr',
      'phone': '+33 6 07 77 88 99',
      'photo_url': 'https://i.pravatar.cc/150?img=7',
      'rating': 4.8,
      'available': 0,
    },
    // ── Neurologie (2) ────────────────────────────────────────────────
    {
      'full_name': 'Dr. Lucas Bernard',
      'specialty': 'Neurologue',
      'domain': 'neurology',
      'email': 'lucas.bernard@carely.fr',
      'phone': '+33 6 45 67 89 01',
      'photo_url': 'https://i.pravatar.cc/150?img=12',
      'rating': 4.6,
      'available': 1,
    },
    {
      'full_name': 'Dr. Sarah Dupuis',
      'specialty': 'Neurologue',
      'domain': 'neurology',
      'email': 'sarah.dupuis@carely.fr',
      'phone': '+33 6 08 88 99 00',
      'photo_url': 'https://i.pravatar.cc/150?img=8',
      'rating': 4.8,
      'available': 1,
    },
    // ── Pédiatrie (3) ─────────────────────────────────────────────────
    {
      'full_name': 'Dr. Fatima Benali',
      'specialty': 'Pédiatre',
      'domain': 'pediatrics',
      'email': 'fatima.benali@carely.fr',
      'phone': '+33 6 56 78 90 12',
      'photo_url': 'https://i.pravatar.cc/150?img=49',
      'rating': 4.9,
      'available': 1,
    },
    {
      'full_name': 'Dr. Nicolas Garnier',
      'specialty': 'Pédiatre',
      'domain': 'pediatrics',
      'email': 'nicolas.garnier@carely.fr',
      'phone': '+33 6 09 99 00 11',
      'photo_url': 'https://i.pravatar.cc/150?img=9',
      'rating': 4.6,
      'available': 1,
    },
    {
      'full_name': 'Dr. Aïcha Diallo',
      'specialty': 'Pédiatre',
      'domain': 'pediatrics',
      'email': 'aicha.diallo@carely.fr',
      'phone': '+33 6 10 00 11 22',
      'photo_url': 'https://i.pravatar.cc/150?img=10',
      'rating': 4.7,
      'available': 1,
    },
    // ── Orthopédie (2) ────────────────────────────────────────────────
    {
      'full_name': 'Dr. Marc Rousseau',
      'specialty': 'Orthopédiste',
      'domain': 'orthopedics',
      'email': 'marc.rousseau@carely.fr',
      'phone': '+33 6 67 89 01 23',
      'photo_url': 'https://i.pravatar.cc/150?img=33',
      'rating': 4.5,
      'available': 0,
    },
    {
      'full_name': 'Dr. Emmanuel Roux',
      'specialty': 'Orthopédiste',
      'domain': 'orthopedics',
      'email': 'emmanuel.roux@carely.fr',
      'phone': '+33 6 13 13 13 13',
      'photo_url': 'https://i.pravatar.cc/150?img=13',
      'rating': 4.6,
      'available': 1,
    },
    // ── Ophtalmologie (3) ─────────────────────────────────────────────
    {
      'full_name': 'Dr. Nadia Kowalski',
      'specialty': 'Ophtalmologue',
      'domain': 'ophthalmology',
      'email': 'nadia.kowalski@carely.fr',
      'phone': '+33 6 78 90 12 34',
      'photo_url': 'https://i.pravatar.cc/150?img=50',
      'rating': 4.8,
      'available': 1,
    },
    {
      'full_name': 'Dr. Julien Mercier',
      'specialty': 'Ophtalmologue',
      'domain': 'ophthalmology',
      'email': 'julien.mercier@carely.fr',
      'phone': '+33 6 14 14 14 14',
      'photo_url': 'https://i.pravatar.cc/150?img=14',
      'rating': 4.4,
      'available': 1,
    },
    {
      'full_name': 'Dr. Priya Sharma',
      'specialty': 'Ophtalmologue',
      'domain': 'ophthalmology',
      'email': 'priya.sharma@carely.fr',
      'phone': '+33 6 16 16 16 16',
      'photo_url': 'https://i.pravatar.cc/150?img=16',
      'rating': 4.7,
      'available': 1,
    },
    // ── Psychiatrie (3) ───────────────────────────────────────────────
    {
      'full_name': 'Dr. Pierre Lefebvre',
      'specialty': 'Psychiatre',
      'domain': 'psychiatry',
      'email': 'pierre.lefebvre@carely.fr',
      'phone': '+33 6 89 01 23 45',
      'photo_url': 'https://i.pravatar.cc/150?img=15',
      'rating': 4.7,
      'available': 1,
    },
    {
      'full_name': 'Dr. Sandrine Blanc',
      'specialty': 'Psychiatre',
      'domain': 'psychiatry',
      'email': 'sandrine.blanc@carely.fr',
      'phone': '+33 6 18 18 18 18',
      'photo_url': 'https://i.pravatar.cc/150?img=18',
      'rating': 4.5,
      'available': 1,
    },
    {
      'full_name': 'Dr. Omar Khalid',
      'specialty': 'Psychiatre',
      'domain': 'psychiatry',
      'email': 'omar.khalid@carely.fr',
      'phone': '+33 6 19 19 19 19',
      'photo_url': 'https://i.pravatar.cc/150?img=19',
      'rating': 4.8,
      'available': 1,
    },
    // ── Dentiste (2) ──────────────────────────────────────────────────
    {
      'full_name': 'Dr. Isabelle Moreau',
      'specialty': 'Dentiste',
      'domain': 'dental',
      'email': 'isabelle.moreau@carely.fr',
      'phone': '+33 6 90 12 34 56',
      'photo_url': 'https://i.pravatar.cc/150?img=51',
      'rating': 4.6,
      'available': 1,
    },
    {
      'full_name': 'Dr. Karim Benali',
      'specialty': 'Dentiste',
      'domain': 'dental',
      'email': 'karim.benali@carely.fr',
      'phone': '+33 6 20 20 20 20',
      'photo_url': 'https://i.pravatar.cc/150?img=20',
      'rating': 4.7,
      'available': 1,
    },
    // ── Gynécologie (3) ───────────────────────────────────────────────
    {
      'full_name': 'Dr. Jean-Paul Tremblay',
      'specialty': 'Gynécologue',
      'domain': 'gynecology',
      'email': 'jp.tremblay@carely.fr',
      'phone': '+33 6 01 23 45 67',
      'photo_url': 'https://i.pravatar.cc/150?img=17',
      'rating': 4.8,
      'available': 1,
    },
    {
      'full_name': 'Dr. Lucie Vidal',
      'specialty': 'Gynécologue',
      'domain': 'gynecology',
      'email': 'lucie.vidal@carely.fr',
      'phone': '+33 6 21 21 21 21',
      'photo_url': 'https://i.pravatar.cc/150?img=21',
      'rating': 4.9,
      'available': 1,
    },
    {
      'full_name': 'Dr. Rosa Pérez',
      'specialty': 'Gynécologue',
      'domain': 'gynecology',
      'email': 'rosa.perez@carely.fr',
      'phone': '+33 6 22 22 22 22',
      'photo_url': 'https://i.pravatar.cc/150?img=22',
      'rating': 4.6,
      'available': 1,
    },
  ];
}
