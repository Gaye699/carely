const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const Database = require('better-sqlite3');
const rateLimit = require('express-rate-limit');
const path = require('path');

require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  console.error('FATAL: JWT_SECRET manquant dans .env');
  process.exit(1);
}

// BASE DE DONNÉES

const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'carely.db');
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
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

  CREATE TABLE IF NOT EXISTS doctors (
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
    createdAt   TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS time_slots (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    doctorId INTEGER NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    dateTime TEXT NOT NULL,
    isBooked INTEGER DEFAULT 0,
    UNIQUE(doctorId, dateTime)
  );

  CREATE TABLE IF NOT EXISTS appointments (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    patientId       INTEGER NOT NULL REFERENCES users(id),
    doctorId        INTEGER NOT NULL REFERENCES doctors(id),
    slotId          INTEGER REFERENCES time_slots(id),
    doctorName      TEXT NOT NULL,
    doctorSpecialty TEXT NOT NULL,
    dateTime        TEXT NOT NULL,
    reason          TEXT,
    status          TEXT DEFAULT 'confirmed'
                    CHECK(status IN ('confirmed','cancelled','completed')),
    createdAt       TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS doctor_availability (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    doctorId  INTEGER NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    dayOfWeek INTEGER NOT NULL CHECK(dayOfWeek BETWEEN 1 AND 7),
    startHour INTEGER NOT NULL,
    endHour   INTEGER NOT NULL,
    UNIQUE(doctorId, dayOfWeek, startHour)
  );

  CREATE TABLE IF NOT EXISTS rpps_registry (
    rppsNumber TEXT PRIMARY KEY,
    firstName  TEXT NOT NULL,
    lastName   TEXT NOT NULL,
    specialty  TEXT NOT NULL
  );
`);

// Migrations pour les colonnes ajoutées
const _addCol = (table, col, def) => {
  try { db.exec(`ALTER TABLE ${table} ADD COLUMN ${col} ${def}`); } catch (_) {}
};
_addCol('doctors', 'userId',     'INTEGER REFERENCES users(id)');
_addCol('doctors', 'rppsNumber', 'TEXT');
_addCol('doctors', 'isVerified', 'INTEGER DEFAULT 0');

// MIDDLEWARES

app.use(cors());
app.use(express.json());

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { error: 'Trop de tentatives. Réessayez dans 15 minutes.' },
});

function authenticate(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token manquant' });
  }
  try {
    req.user = jwt.verify(auth.slice(7), JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Token invalide ou expiré' });
  }
}

function requireAdmin(req, res, next) {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Accès réservé aux administrateurs' });
  }
  next();
}

// HEALTH

app.get('/health', (_, res) => res.json({ status: 'ok' }));

// AUTH

// POST
app.post('/api/auth/register', async (req, res) => {
  const { firstName, lastName, email, password, phone, role, specialty, rppsNumber, avatarUrl } = req.body;

  if (!firstName || !lastName || !email || !password) {
    return res.status(400).json({ error: 'Tous les champs obligatoires doivent être remplis' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'Le mot de passe doit contenir au moins 8 caractères' });
  }

  const userRole = role === 'doctor' ? 'doctor' : 'patient';

  if (userRole === 'doctor') {
    if (!rppsNumber || !/^\d{11}$/.test(rppsNumber.trim())) {
      return res.status(400).json({ error: 'Le numéro RPPS doit contenir exactement 11 chiffres' });
    }
    // Vérifier que le RPPS existe dans le registre national
    const rppsEntry = db.prepare('SELECT * FROM rpps_registry WHERE rppsNumber = ?').get(rppsNumber.trim());
    if (!rppsEntry) {
      return res.status(400).json({
        error: 'Numéro RPPS non reconnu dans le registre national. Vérifiez votre numéro ou contactez l\'ANS.',
      });
    }
    // Vérifier qu'il n'est pas déjà utilisé
    const existingRpps = db.prepare('SELECT id FROM doctors WHERE rppsNumber = ?').get(rppsNumber.trim());
    if (existingRpps) return res.status(409).json({ error: 'Ce numéro RPPS est déjà associé à un compte' });
  }

  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
  if (existing) return res.status(409).json({ error: 'Email déjà utilisé' });

  const hashed = await bcrypt.hash(password, 12);

  const registerTx = db.transaction(() => {
    const userResult = db
      .prepare('INSERT INTO users (firstName, lastName, email, password, role, phone, avatarUrl) VALUES (?, ?, ?, ?, ?, ?, ?)')
      .run(firstName, lastName, email, hashed, userRole, phone || null, avatarUrl || null);

    const userId = userResult.lastInsertRowid;

    if (userRole === 'doctor') {
      // Le RPPS est validé → isVerified = 1 automatiquement
      const rppsEntry = db.prepare('SELECT * FROM rpps_registry WHERE rppsNumber = ?').get(rppsNumber.trim());
      const docSpecialty = rppsEntry?.specialty || specialty || 'Médecin';
      db.prepare(
        'INSERT INTO doctors (firstName, lastName, specialty, userId, rppsNumber, isVerified) VALUES (?, ?, ?, ?, ?, 1)'
      ).run(firstName, lastName, docSpecialty, userId, rppsNumber.trim());
    }

    return userId;
  });

  const userId = registerTx();

  const token = jwt.sign(
    { id: userId, email, role: userRole },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  res.status(201).json({
    token,
    user: { id: userId, firstName, lastName, email, role: userRole },
  });
});

// POST
app.post('/api/auth/login', loginLimiter, async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email et mot de passe requis' });
  }

  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  const invalid = () => res.status(401).json({ error: 'Identifiants invalides' });

  if (!user) return invalid();

  const match = await bcrypt.compare(password, user.password);
  if (!match) return invalid();

  const token = jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  const { password: _pwd, ...safeUser } = user;
  res.json({ token, user: safeUser });
});

// GET
app.get('/api/auth/me', authenticate, (req, res) => {
  const user = db
    .prepare('SELECT id, firstName, lastName, email, role, phone, avatarUrl, createdAt FROM users WHERE id = ?')
    .get(req.user.id);
  if (!user) return res.status(404).json({ error: 'Utilisateur introuvable' });
  res.json(user);
});

// PUT — mise à jour du profil patient
app.put('/api/auth/profile', authenticate, (req, res) => {
  const { firstName, lastName, phone, avatarUrl } = req.body;
  db.prepare(`
    UPDATE users SET
      firstName = COALESCE(?, firstName),
      lastName  = COALESCE(?, lastName),
      phone     = COALESCE(?, phone),
      avatarUrl = COALESCE(?, avatarUrl)
    WHERE id = ?
  `).run(firstName || null, lastName || null, phone || null, avatarUrl || null, req.user.id);
  const user = db.prepare(
    'SELECT id, firstName, lastName, email, role, phone, avatarUrl FROM users WHERE id = ?'
  ).get(req.user.id);
  res.json(user);
});

// PUT
app.put('/api/users/avatar', authenticate, (req, res) => {
  const { avatarUrl } = req.body;
  if (!avatarUrl) return res.status(400).json({ error: 'avatarUrl requis' });
  db.prepare('UPDATE users SET avatarUrl = ? WHERE id = ?').run(avatarUrl, req.user.id);
  res.json({ avatarUrl });
});

// DOCTORS

// GET
app.get('/api/doctors', authenticate, (req, res) => {
  const { specialty, search } = req.query;
  // Patients voient uniquement les médecins vérifiés. Admin et doctors voient tout.
  const verifiedOnly = req.user.role === 'patient';
  let query = `SELECT * FROM doctors WHERE isActive = 1${verifiedOnly ? ' AND isVerified = 1' : ''}`;
  const params = [];

  if (specialty) {
    query += ' AND specialty = ?';
    params.push(specialty);
  }
  if (search) {
    query += ' AND (firstName LIKE ? OR lastName LIKE ? OR specialty LIKE ? OR city LIKE ?)';
    const like = `%${search}%`;
    params.push(like, like, like, like);
  }

  query += ' ORDER BY rating DESC';
  res.json(db.prepare(query).all(...params));
});

// GET
app.get('/api/doctors/:id', authenticate, (req, res) => {
  const doctor = db
    .prepare('SELECT * FROM doctors WHERE id = ? AND isActive = 1')
    .get(req.params.id);
  if (!doctor) return res.status(404).json({ error: 'Médecin introuvable' });
  res.json(doctor);
});

// GET — créneaux d'un médecin (générés depuis ses disponibilités hebdomadaires)
app.get('/api/doctors/:id/slots', authenticate, (req, res) => {
  const doctorId = req.params.id;
  const { date } = req.query;

  const availability = db.prepare(
    'SELECT * FROM doctor_availability WHERE doctorId = ?'
  ).all(doctorId);

  // Si le médecin n'a pas défini de disponibilités, retourner les créneaux manuels
  if (availability.length === 0) {
    let q = `SELECT * FROM time_slots WHERE doctorId = ? AND isBooked = 0 AND dateTime > datetime('now')`;
    const p = [doctorId];
    if (date) { q += ' AND date(dateTime) = date(?)'; p.push(date); }
    q += ' ORDER BY dateTime ASC';
    return res.json(db.prepare(q).all(...p));
  }

  // Générer les créneaux de 30 min pour les 14 prochains jours
  const slots = [];
  const now = new Date();


  const toDbDay = (jsDay) => jsDay === 0 ? 7 : jsDay;

  for (let dayOffset = 0; dayOffset < 14; dayOffset++) {
    const d = new Date(now);
    d.setDate(d.getDate() + dayOffset);
    const dbDay = toDbDay(d.getDay());
    const dateStr = d.toISOString().substring(0, 10);

    // Filtrer sur la date demandée si précisée
    if (date && dateStr !== date) continue;

    const daySlots = availability.filter(a => a.dayOfWeek === dbDay);
    for (const avail of daySlots) {
      // Créneaux de 30 min
      for (let h = avail.startHour; h < avail.endHour; h++) {
        for (const min of [0, 30]) {
          if (h === avail.endHour - 1 && min === 30) continue; // ne pas dépasser endHour
          const timeStr = `${h.toString().padStart(2, '0')}:${min.toString().padStart(2, '0')}`;
          const dateTime = `${dateStr}T${timeStr}`;

          // Ignorer les créneaux passés
          if (new Date(dateTime) <= now) continue;

          // Vérifier si ce créneau est déjà réservé dans appointments
          const booked = db.prepare(
            "SELECT id FROM appointments WHERE doctorId = ? AND dateTime = ? AND status = 'confirmed'"
          ).get(doctorId, dateTime);

          if (!booked) {
            slots.push({ dateTime, time: timeStr, date: dateStr });
          }
        }
      }
    }
  }

  res.json(slots);
});




app.post('/api/appointments', authenticate, (req, res) => {
  const { doctorId, dateTime, slotId, reason } = req.body;

  if (!doctorId || (!dateTime && !slotId)) {
    return res.status(400).json({ error: 'doctorId et dateTime (ou slotId) sont requis' });
  }

  const doctor = db.prepare('SELECT * FROM doctors WHERE id = ? AND isActive = 1').get(doctorId);
  if (!doctor) return res.status(404).json({ error: 'Médecin introuvable' });


  let finalDateTime = dateTime;
  let resolvedSlotId = slotId || null;

  if (!finalDateTime && slotId) {
    const slot = db.prepare('SELECT * FROM time_slots WHERE id = ? AND isBooked = 0').get(slotId);
    if (!slot) return res.status(409).json({ error: 'Créneau indisponible ou déjà réservé' });
    finalDateTime = slot.dateTime;
    resolvedSlotId = slot.id;
  }

  // Vérifier conflit (double réservation)
  const conflict = db.prepare(
    "SELECT id FROM appointments WHERE doctorId = ? AND dateTime = ? AND status = 'confirmed'"
  ).get(doctorId, finalDateTime);
  if (conflict) return res.status(409).json({ error: 'Ce créneau est déjà réservé' });

  const book = db.transaction(() => {
    if (resolvedSlotId) {
      db.prepare('UPDATE time_slots SET isBooked = 1 WHERE id = ?').run(resolvedSlotId);
    }
    return db.prepare(
      `INSERT INTO appointments (patientId, doctorId, slotId, doctorName, doctorSpecialty, dateTime, reason)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    ).run(
      req.user.id, doctorId, resolvedSlotId,
      `${doctor.firstName} ${doctor.lastName}`,
      doctor.specialty, finalDateTime, reason || null
    );
  });

  const result = book();
  res.status(201).json(db.prepare('SELECT * FROM appointments WHERE id = ?').get(result.lastInsertRowid));
});

// GET
app.get('/api/appointments/mine', authenticate, (req, res) => {
  res.json(
    db
      .prepare('SELECT * FROM appointments WHERE patientId = ? ORDER BY dateTime DESC')
      .all(req.user.id)
  );
});

// PUT
app.put('/api/appointments/:id/cancel', authenticate, (req, res) => {
  const appt = db
    .prepare('SELECT * FROM appointments WHERE id = ? AND patientId = ?')
    .get(req.params.id, req.user.id);
  if (!appt) return res.status(404).json({ error: 'Rendez-vous introuvable' });
  if (appt.status !== 'confirmed') {
    return res.status(400).json({ error: 'Ce rendez-vous ne peut plus être annulé' });
  }

  db.transaction(() => {
    db.prepare('UPDATE appointments SET status = ? WHERE id = ?').run('cancelled', appt.id);
    if (appt.slotId) {
      db.prepare('UPDATE time_slots SET isBooked = 0 WHERE id = ?').run(appt.slotId);
    }
  })();

  res.json({ message: 'Rendez-vous annulé' });
});

// ADMIN

// GET
app.get('/api/admin/stats', authenticate, requireAdmin, (_, res) => {
  res.json({
    totalDoctors: db.prepare('SELECT COUNT(*) as n FROM doctors WHERE isActive = 1').get().n,
    totalPatients: db.prepare("SELECT COUNT(*) as n FROM users WHERE role = 'patient'").get().n,
    totalAppointments: db.prepare('SELECT COUNT(*) as n FROM appointments').get().n,
    confirmedAppointments: db.prepare("SELECT COUNT(*) as n FROM appointments WHERE status = 'confirmed'").get().n,
  });
});

// POST
app.post('/api/admin/doctors', authenticate, requireAdmin, (req, res) => {
  const { firstName, lastName, specialty, description, address, city, phone, avatarUrl, price } = req.body;

  if (!firstName || !lastName || !specialty) {
    return res.status(400).json({ error: 'firstName, lastName et specialty sont requis' });
  }

  const result = db
    .prepare(
      'INSERT INTO doctors (firstName, lastName, specialty, description, address, city, phone, avatarUrl, price) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    )
    .run(firstName, lastName, specialty, description || null, address || null, city || null, phone || null, avatarUrl || null, price || 0);

  res.status(201).json(db.prepare('SELECT * FROM doctors WHERE id = ?').get(result.lastInsertRowid));
});

// POST
app.post('/api/admin/doctors/:id/slots', authenticate, requireAdmin, (req, res) => {
  const { slots } = req.body;

  if (!Array.isArray(slots) || slots.length === 0) {
    return res.status(400).json({ error: 'slots doit être un tableau non vide de dates ISO 8601' });
  }

  const insert = db.prepare('INSERT OR IGNORE INTO time_slots (doctorId, dateTime) VALUES (?, ?)');
  db.transaction(() => slots.forEach((dt) => insert.run(req.params.id, dt)))();

  res.status(201).json({ message: `${slots.length} créneau(x) ajouté(s)` });
});

// PUT
app.put('/api/admin/doctors/:id', authenticate, requireAdmin, (req, res) => {
  const doctor = db.prepare('SELECT id FROM doctors WHERE id = ?').get(req.params.id);
  if (!doctor) return res.status(404).json({ error: 'Médecin introuvable' });

  const { firstName, lastName, specialty, description, address, city, phone, avatarUrl, price, rating, reviewCount } = req.body;

  db.prepare(`
    UPDATE doctors SET
      firstName   = COALESCE(?, firstName),
      lastName    = COALESCE(?, lastName),
      specialty   = COALESCE(?, specialty),
      description = COALESCE(?, description),
      address     = COALESCE(?, address),
      city        = COALESCE(?, city),
      phone       = COALESCE(?, phone),
      avatarUrl   = COALESCE(?, avatarUrl),
      price       = COALESCE(?, price),
      rating      = COALESCE(?, rating),
      reviewCount = COALESCE(?, reviewCount)
    WHERE id = ?
  `).run(firstName, lastName, specialty, description, address, city, phone, avatarUrl, price, rating, reviewCount, req.params.id);

  res.json(db.prepare('SELECT * FROM doctors WHERE id = ?').get(req.params.id));
});

// DELETE
app.delete('/api/admin/doctors/:id', authenticate, requireAdmin, (req, res) => {
  const result = db.prepare('UPDATE doctors SET isActive = 0 WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'Médecin introuvable' });
  res.json({ message: 'Médecin désactivé' });
});

// GET — médecins en attente de vérification
app.get('/api/admin/pending-doctors', authenticate, requireAdmin, (_, res) => {
  res.json(db.prepare('SELECT * FROM doctors WHERE isVerified = 0 AND isActive = 1 ORDER BY createdAt DESC').all());
});

// PUT — vérifier un médecin
app.put('/api/admin/doctors/:id/verify', authenticate, requireAdmin, (req, res) => {
  const result = db.prepare('UPDATE doctors SET isVerified = 1 WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'Médecin introuvable' });
  res.json(db.prepare('SELECT * FROM doctors WHERE id = ?').get(req.params.id));
});

// PORTAIL MÉDECIN

function requireDoctor(req, res, next) {
  if (req.user.role !== 'doctor') {
    return res.status(403).json({ error: 'Accès réservé aux médecins' });
  }
  next();
}

// GET — profil du médecin connecté
app.get('/api/doctor/me', authenticate, requireDoctor, (req, res) => {
  const doctor = db.prepare('SELECT * FROM doctors WHERE userId = ? AND isActive = 1').get(req.user.id);
  if (!doctor) return res.status(404).json({ error: 'Profil médecin introuvable' });
  res.json(doctor);
});

// PUT — mettre à jour son profil
app.put('/api/doctor/me', authenticate, requireDoctor, (req, res) => {
  const doctor = db.prepare('SELECT id FROM doctors WHERE userId = ?').get(req.user.id);
  if (!doctor) return res.status(404).json({ error: 'Profil médecin introuvable' });

  const { description, address, city, phone, avatarUrl, price } = req.body;
  db.prepare(`
    UPDATE doctors SET
      description = COALESCE(?, description),
      address     = COALESCE(?, address),
      city        = COALESCE(?, city),
      phone       = COALESCE(?, phone),
      avatarUrl   = COALESCE(?, avatarUrl),
      price       = COALESCE(?, price)
    WHERE id = ?
  `).run(description, address, city, phone, avatarUrl, price, doctor.id);

  // Sync avatarUrl dans users aussi
  if (avatarUrl) db.prepare('UPDATE users SET avatarUrl = ? WHERE id = ?').run(avatarUrl, req.user.id);

  res.json(db.prepare('SELECT * FROM doctors WHERE id = ?').get(doctor.id));
});

// GET — rendez-vous du médecin (aujourd'hui + à venir)
app.get('/api/doctor/appointments', authenticate, requireDoctor, (req, res) => {
  const doctor = db.prepare('SELECT id FROM doctors WHERE userId = ?').get(req.user.id);
  if (!doctor) return res.status(404).json({ error: 'Profil médecin introuvable' });

  const { filter } = req.query; // 'today' | 'upcoming' | all (default)
  let query = `
    SELECT a.*, u.firstName as patientFirstName, u.lastName as patientLastName, u.phone as patientPhone
    FROM appointments a
    JOIN users u ON u.id = a.patientId
    WHERE a.doctorId = ? AND a.status = 'confirmed'
  `;
  const params = [doctor.id];

  if (filter === 'today') {
    query += " AND date(a.dateTime) = date('now')";
  } else if (filter === 'upcoming') {
    query += " AND a.dateTime > datetime('now')";
  }

  query += ' ORDER BY a.dateTime ASC';
  res.json(db.prepare(query).all(...params));
});

// GET — disponibilités du médecin
app.get('/api/doctor/availability', authenticate, requireDoctor, (req, res) => {
  const doctor = db.prepare('SELECT id FROM doctors WHERE userId = ?').get(req.user.id);
  if (!doctor) return res.status(404).json({ error: 'Profil médecin introuvable' });
  res.json(db.prepare('SELECT * FROM doctor_availability WHERE doctorId = ? ORDER BY dayOfWeek, startHour').all(doctor.id));
});

// POST — définir ses disponibilités
app.post('/api/doctor/availability', authenticate, requireDoctor, (req, res) => {
  const doctor = db.prepare('SELECT id FROM doctors WHERE userId = ?').get(req.user.id);
  if (!doctor) return res.status(404).json({ error: 'Profil médecin introuvable' });

  const { slots } = req.body; 
  if (!Array.isArray(slots)) return res.status(400).json({ error: 'slots doit être un tableau' });

  db.transaction(() => {
    db.prepare('DELETE FROM doctor_availability WHERE doctorId = ?').run(doctor.id);
    const insert = db.prepare(
      'INSERT INTO doctor_availability (doctorId, dayOfWeek, startHour, endHour) VALUES (?, ?, ?, ?)'
    );
    for (const s of slots) {
      if (s.dayOfWeek >= 1 && s.dayOfWeek <= 7 && s.startHour < s.endHour) {
        insert.run(doctor.id, s.dayOfWeek, s.startHour, s.endHour);
      }
    }
  })();

  res.status(201).json({ message: 'Disponibilités enregistrées' });
});

// GET — disponibilités d'un médecin (pour le patient)
app.get('/api/doctors/:id/availability', authenticate, (req, res) => {
  res.json(
    db.prepare('SELECT * FROM doctor_availability WHERE doctorId = ? ORDER BY dayOfWeek, startHour').all(req.params.id)
  );
});

// DÉMARRAGE

app.listen(PORT, () => {
  console.log(` Carely API démarrée sur http://localhost:${PORT}`);
  console.log(`   GET http://localhost:${PORT}/health`);
});
