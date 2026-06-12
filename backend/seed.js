// Exécuter avec : node seed.js
// Remet la BDD à zéro avec des données de démonstration.

const Database = require('better-sqlite3');
const bcrypt = require('bcrypt');
const path = require('path');

const db = new Database(path.join(__dirname, 'carely.db'));
db.pragma('foreign_keys = ON');

// Nettoyage
db.prepare('DELETE FROM appointments').run();
db.prepare('DELETE FROM time_slots').run();
db.prepare('DELETE FROM doctors').run();
db.prepare('DELETE FROM users').run();

// Utilisateurs
const adminHash  = bcrypt.hashSync('Admin1234!', 12);
const patientHash = bcrypt.hashSync('Demo1234!', 12);

db.prepare("INSERT INTO users (firstName, lastName, email, password, role) VALUES (?, ?, ?, ?, ?)")
  .run('Admin', 'Carely', 'admin@carely.fr', adminHash, 'admin');

db.prepare("INSERT INTO users (firstName, lastName, email, password, role) VALUES (?, ?, ?, ?, ?)")
  .run('Jean', 'Patient', 'patient@carely.fr', patientHash, 'patient');

// Médecins
const doctors = [
  {
    firstName: 'Martin', lastName: 'Leblanc', specialty: 'Cardiologue',
    description: 'Cardiologue expérimenté avec 15 ans de pratique hospitalière.',
    address: '12 rue de la Paix', city: 'Paris', phone: '01 23 45 67 89',
    rating: 4.9, reviewCount: 142, price: 35,
  },
  {
    firstName: 'Sophie', lastName: 'Roux', specialty: 'Pédiatre',
    description: 'Pédiatre dévoués aux soins des enfants de 0 à 16 ans.',
    address: '5 avenue des Fleurs', city: 'Lyon', phone: '04 56 78 90 12',
    rating: 4.8, reviewCount: 98, price: 28,
  },
  {
    firstName: 'Karim', lastName: 'Benali', specialty: 'Dentiste',
    description: 'Spécialisé en implantologie et esthétique dentaire.',
    address: '8 rue Victor Hugo', city: 'Marseille', phone: '04 91 23 45 67',
    rating: 4.7, reviewCount: 203, price: 45,
  },
  {
    firstName: 'Claire', lastName: 'Morel', specialty: 'Dermatologue',
    description: 'Experte en dermatologie médicale et esthétique.',
    address: '3 place du Marché', city: 'Toulouse', phone: '05 34 56 78 90',
    rating: 4.6, reviewCount: 77, price: 40,
  },
  {
    firstName: 'Pierre', lastName: 'Fontaine', specialty: 'Généraliste',
    description: 'Médecin généraliste avec une approche globale de la santé.',
    address: '20 bd de la République', city: 'Bordeaux', phone: '05 56 78 90 12',
    rating: 4.5, reviewCount: 310, price: 25,
  },
];

const insertDoctor = db.prepare(
  'INSERT INTO doctors (firstName, lastName, specialty, description, address, city, phone, rating, reviewCount, price) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
);

doctors.forEach((d) => {
  insertDoctor.run(d.firstName, d.lastName, d.specialty, d.description, d.address, d.city, d.phone, d.rating, d.reviewCount, d.price);
});

// Créneaux
const insertSlot = db.prepare('INSERT OR IGNORE INTO time_slots (doctorId, dateTime) VALUES (?, ?)');
const hours = [9, 10, 11, 14, 15, 16, 17];
const now = new Date();

db.transaction(() => {
  for (let doctorId = 1; doctorId <= 5; doctorId++) {
    for (let day = 1; day <= 7; day++) {
      hours.forEach((h) => {
        const d = new Date(now);
        d.setDate(d.getDate() + day);
        d.setHours(h, 0, 0, 0);
        const iso = d.toISOString().slice(0, 19);
        insertSlot.run(doctorId, iso);
      });
    }
  }
})();

console.log('✅ Seed terminé :');
console.log('   - 2 utilisateurs (admin@carely.fr / patient@carely.fr)');
console.log('   - 5 médecins');
console.log('   - Créneaux sur 7 jours (lun-dim, 9h-17h)');
