
const Database = require('better-sqlite3');
const bcrypt = require('bcrypt');
const path = require('path');

const db = new Database(path.join(__dirname, 'carely.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = OFF'); // désactivé pendant la création du schéma et le nettoyage

// ─── Schéma : DROP + CREATE pour garantir le bon schéma ───────────────────
db.exec(`
  DROP TABLE IF EXISTS appointments;
  DROP TABLE IF EXISTS time_slots;
  DROP TABLE IF EXISTS doctor_availability;
  DROP TABLE IF EXISTS doctors;
  DROP TABLE IF EXISTS users;
  DROP TABLE IF EXISTS rpps_registry;

  CREATE TABLE users (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    firstName TEXT NOT NULL,
    lastName  TEXT NOT NULL,
    email     TEXT NOT NULL UNIQUE COLLATE NOCASE,
    password  TEXT NOT NULL,
    role      TEXT DEFAULT 'patient' CHECK(role IN ('patient','admin','doctor')),
    phone     TEXT,
    avatarUrl TEXT,
    createdAt TEXT DEFAULT (datetime('now'))
  );
  CREATE TABLE doctors (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    firstName   TEXT NOT NULL,
    lastName    TEXT NOT NULL,
    specialty   TEXT NOT NULL,
    description TEXT,
    address     TEXT,
    city        TEXT,
    phone       TEXT,
    avatarUrl   TEXT,
    rating      REAL DEFAULT 0,
    reviewCount INTEGER DEFAULT 0,
    price       REAL DEFAULT 0,
    isActive    INTEGER DEFAULT 1,
    userId      INTEGER,
    rppsNumber  TEXT,
    isVerified  INTEGER DEFAULT 0,
    createdAt   TEXT DEFAULT (datetime('now'))
  );
  CREATE TABLE time_slots (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    doctorId INTEGER NOT NULL,
    dateTime TEXT NOT NULL,
    isBooked INTEGER DEFAULT 0,
    UNIQUE(doctorId, dateTime)
  );
  CREATE TABLE appointments (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    patientId       INTEGER NOT NULL,
    doctorId        INTEGER NOT NULL,
    slotId          INTEGER,
    doctorName      TEXT NOT NULL,
    doctorSpecialty TEXT NOT NULL,
    dateTime        TEXT NOT NULL,
    reason          TEXT,
    status          TEXT DEFAULT 'confirmed' CHECK(status IN ('confirmed','cancelled','completed')),
    createdAt       TEXT DEFAULT (datetime('now'))
  );
  CREATE TABLE doctor_availability (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    doctorId  INTEGER NOT NULL,
    dayOfWeek INTEGER NOT NULL CHECK(dayOfWeek BETWEEN 1 AND 7),
    startHour INTEGER NOT NULL,
    endHour   INTEGER NOT NULL,
    UNIQUE(doctorId, dayOfWeek, startHour)
  );
  CREATE TABLE rpps_registry (
    rppsNumber TEXT PRIMARY KEY,
    firstName  TEXT NOT NULL,
    lastName   TEXT NOT NULL,
    specialty  TEXT NOT NULL
  );
`);

// ─── Nettoyage ─────────────────────────────────────────────────────────────
for (const t of ['appointments','time_slots','doctor_availability','doctors','users','rpps_registry']) {
  try { db.prepare(`DELETE FROM "${t}"`).run(); } catch (_) {}
}
try {
  db.prepare(`DELETE FROM sqlite_sequence`).run();
} catch (_) {}

db.pragma('foreign_keys = ON');

// Registre RPPS
// Ces numéros simulent le registre national pour la démo.
const rppsData = [
  // 3 médecins pré-seedés
  { rppsNumber: '10003491001', firstName: 'Martin',  lastName: 'Leblanc',  specialty: 'Cardiologue' },
  { rppsNumber: '10003491002', firstName: 'Sophie',  lastName: 'Roux',     specialty: 'Pédiatre' },
  { rppsNumber: '10003491003', firstName: 'Karim',   lastName: 'Benali',   specialty: 'Dentiste' },
  // médecins par en encore seedé
  { rppsNumber: '10003491004', firstName: 'Claire',  lastName: 'Morel',    specialty: 'Dermatologue' },
  { rppsNumber: '10003491005', firstName: 'Pierre',  lastName: 'Fontaine', specialty: 'Médecin généraliste' },
  { rppsNumber: '10003491006', firstName: 'Amina',   lastName: 'Sow',      specialty: 'Dermatologue' },
  { rppsNumber: '10003491007', firstName: 'Lucas',   lastName: 'Bernard',  specialty: 'Neurologue' },
  { rppsNumber: '10003491008', firstName: 'Fatima',  lastName: 'Benali',   specialty: 'Pédiatre' },
  { rppsNumber: '10003491009', firstName: 'Marc',    lastName: 'Rousseau', specialty: 'Orthopédiste' },
  { rppsNumber: '10003491010', firstName: 'Nadia',   lastName: 'Kowalski', specialty: 'Ophtalmologue' },
];

const insertRpps = db.prepare(
  'INSERT OR IGNORE INTO rpps_registry (rppsNumber, firstName, lastName, specialty) VALUES (?, ?, ?, ?)'
);
rppsData.forEach(r => insertRpps.run(r.rppsNumber, r.firstName, r.lastName, r.specialty));

// Patient
const patientHash = bcrypt.hashSync('Demo1234!', 12);
db.prepare('INSERT INTO users (firstName, lastName, email, password, role) VALUES (?, ?, ?, ?, ?)')
  .run('Jean', 'Patient', 'patient@carely.fr', patientHash, 'patient');

//  3 comptes médecins pré-vérifiés
const doctorPassword = bcrypt.hashSync('Doctor1234!', 12);

const doctorAccounts = [
  {
    email: 'martin.leblanc@carely.fr', rppsNumber: '10003491001',
    firstName: 'Martin', lastName: 'Leblanc', specialty: 'Cardiologue',
    description: "Cardiologue expérimenté avec 15 ans de pratique hospitalière. Spécialisé dans le suivi des maladies coronariennes et l'insuffisance cardiaque.",
    address: '12 rue de la Paix', city: 'Paris', phone: '01 23 45 67 89',
    avatarUrl: 'https://i.pravatar.cc/150?img=11',
    rating: 4.9, reviewCount: 142, price: 35,
  },
  {
    email: 'sophie.roux@carely.fr', rppsNumber: '10003491002',
    firstName: 'Sophie', lastName: 'Roux', specialty: 'Pédiatre',
    description: "Pédiatre dévoués aux soins des enfants de 0 à 16 ans. Approche douce et bienveillante pour mettre les enfants et les parents à l'aise.",
    address: '5 avenue des Fleurs', city: 'Lyon', phone: '04 56 78 90 12',
    avatarUrl: 'https://i.pravatar.cc/150?img=47',
    rating: 4.8, reviewCount: 98, price: 28,
  },
  {
    email: 'karim.benali@carely.fr', rppsNumber: '10003491003',
    firstName: 'Karim', lastName: 'Benali', specialty: 'Dentiste',
    description: "Spécialisé en implantologie et esthétique dentaire. Cabinet entièrement équipé des dernières technologies numériques.",
    address: '8 rue Victor Hugo', city: 'Marseille', phone: '04 91 23 45 67',
    avatarUrl: 'https://i.pravatar.cc/150?img=52',
    rating: 4.7, reviewCount: 203, price: 45,
  },
];

const insertUser = db.prepare(
  'INSERT INTO users (firstName, lastName, email, password, role) VALUES (?, ?, ?, ?, ?)'
);
const insertDoctor = db.prepare(`
  INSERT INTO doctors
    (firstName, lastName, specialty, description, address, city, phone, avatarUrl,
     rating, reviewCount, price, userId, rppsNumber, isVerified)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
`);

const doctorIds = doctorAccounts.map(d => {
  const u = insertUser.run(d.firstName, d.lastName, d.email, doctorPassword, 'doctor');
  const dr = insertDoctor.run(
    d.firstName, d.lastName, d.specialty, d.description,
    d.address, d.city, d.phone, d.avatarUrl,
    d.rating, d.reviewCount, d.price,
    u.lastInsertRowid, d.rppsNumber
  );
  return dr.lastInsertRowid;
});

// Disponibilités
const insertAvail = db.prepare(
  'INSERT INTO doctor_availability (doctorId, dayOfWeek, startHour, endHour) VALUES (?, ?, ?, ?)'
);
db.transaction(() => {
  for (const id of doctorIds) {
    for (let day = 1; day <= 5; day++) {
      insertAvail.run(id, day, 9, 12);
      insertAvail.run(id, day, 14, 17);
    }
  }
})();

// Créneaux legacy
const insertSlot = db.prepare('INSERT OR IGNORE INTO time_slots (doctorId, dateTime) VALUES (?, ?)');
const hours = [9, 10, 11, 14, 15, 16];
const now = new Date();

db.transaction(() => {
  for (const doctorId of doctorIds) {
    for (let day = 1; day <= 7; day++) {
      for (const h of hours) {
        const d = new Date(now);
        d.setDate(d.getDate() + day);
        d.setHours(h, 0, 0, 0);
        insertSlot.run(doctorId, d.toISOString().slice(0, 16));
      }
    }
  }
})();

// ------------------------------
console.log('\n Seed terminé !');
console.log('');
console.log('  PATIENT');
console.log('   patient@carely.fr        / Demo1234!');
console.log('');
console.log('  MÉDECINS (portail médecin)');
console.log('   martin.leblanc@carely.fr / Doctor1234!  → Cardiologue, Paris');
console.log('   sophie.roux@carely.fr    / Doctor1234!  → Pédiatre, Lyon');
console.log('   karim.benali@carely.fr   / Doctor1234!  → Dentiste, Marseille');
console.log('');
console.log('  RPPS disponibles pour s\'inscrire via l\'app :');
console.log('   10003491004  Claire Morel      Dermatologue');
console.log('   10003491005  Pierre Fontaine   Médecin généraliste');
console.log('   10003491006  Amina Sow         Dermatologue');
console.log('   10003491007  Lucas Bernard     Neurologue');
console.log('   10003491008  Fatima Benali     Pédiatre');
console.log('   10003491009  Marc Rousseau     Orthopédiste');
console.log('   10003491010  Nadia Kowalski    Ophtalmologue');
