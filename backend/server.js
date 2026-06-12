const express    = require('express');
const Database   = require('better-sqlite3');
const bcrypt     = require('bcryptjs');
const jwt        = require('jsonwebtoken');
const cors       = require('cors');
const helmet     = require('helmet');
const rateLimit  = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const path       = require('path');

const app = express();
const PORT       = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_moi';

// ── Base de données ──────────────────────────────────────────────────────────
const db = new Database(path.join(__dirname, 'carely.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    firstName TEXT NOT NULL,
    lastName  TEXT NOT NULL,
    email     TEXT NOT NULL UNIQUE COLLATE NOCASE,
    password  TEXT NOT NULL,
    role      TEXT NOT NULL DEFAULT 'patient' CHECK(role IN ('patient','admin')),
    phone     TEXT,
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
`);

// ── Sécurité ─────────────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({ origin: process.env.ALLOWED_ORIGIN || '*' }));
app.use(express.json({ limit: '10kb' }));

const globalLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 });
const authLimiter   = rateLimit({ windowMs: 15 * 60 * 1000, max: 10 });
app.use('/api', globalLimiter);

// ── Middleware auth ───────────────────────────────────────────────────────────
function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer '))
    return res.status(401).json({ message: 'Token manquant' });
  try {
    req.user = jwt.verify(header.slice(7), JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ message: 'Token invalide ou expiré' });
  }
}

function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin')
    return res.status(403).json({ message: 'Accès réservé aux admins' });
  next();
}

// ── AUTH ──────────────────────────────────────────────────────────────────────
app.post('/api/auth/register', authLimiter,
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }),
    body('firstName').trim().notEmpty(),
    body('lastName').trim().notEmpty(),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res.status(400).json({ message: errors.array()[0].msg });

    const { firstName, lastName, email, password } = req.body;
    if (db.prepare('SELECT id FROM users WHERE email = ?').get(email))
      return res.status(409).json({ message: 'Email déjà utilisé' });

    const hashed = await bcrypt.hash(password, 12);
    const r = db.prepare(
      'INSERT INTO users (firstName, lastName, email, password) VALUES (?,?,?,?)'
    ).run(firstName, lastName, email, hashed);

    const user  = { id: r.lastInsertRowid, firstName, lastName, email, role: 'patient' };
    const token = jwt.sign({ id: user.id, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ token, user });
  }
);

app.post('/api/auth/login', authLimiter,
  [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty(),
  ],
  async (req, res) => {
    const { email, password } = req.body;
    const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
    if (!user || !(await bcrypt.compare(password, user.password)))
      return res.status(401).json({ message: 'Email ou mot de passe incorrect' });

    const token = jwt.sign({ id: user.id, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    const { password: _, ...safe } = user;
    res.json({ token, user: safe });
  }
);

app.get('/api/auth/me', requireAuth, (req, res) => {
  const user = db.prepare(
    'SELECT id, firstName, lastName, email, role, phone FROM users WHERE id = ?'
  ).get(req.user.id);
  if (!user) return res.status(404).json({ message: 'Introuvable' });
  res.json(user);
});

// ── DOCTORS ───────────────────────────────────────────────────────────────────
app.get('/api/doctors', (req, res) => {
  const { specialty, search } = req.query;
  let q = 'SELECT * FROM doctors WHERE isActive = 1';
  const p = [];
  if (specialty) { q += ' AND specialty = ?'; p.push(specialty); }
  if (search) {
    q += ' AND (firstName LIKE ? OR lastName LIKE ? OR specialty LIKE ?)';
    const s = `%${search}%`;
    p.push(s, s, s);
  }
  res.json(db.prepare(q + ' ORDER BY rating DESC').all(...p));
});

app.get('/api/doctors/:id', (req, res) => {
  const doc = db.prepare('SELECT * FROM doctors WHERE id = ? AND isActive = 1')
    .get(req.params.id);
  if (!doc) return res.status(404).json({ message: 'Médecin introuvable' });
  res.json(doc);
});

app.get('/api/doctors/:id/slots', (req, res) => {
  const { date } = req.query;
  let q = 'SELECT * FROM time_slots WHERE doctorId = ? AND isBooked = 0';
  const p = [req.params.id];
  if (date) { q += ' AND dateTime LIKE ?'; p.push(`${date}%`); }
  res.json(db.prepare(q + ' ORDER BY dateTime ASC').all(...p));
});

// ── ADMIN ─────────────────────────────────────────────────────────────────────
app.post('/api/admin/doctors', requireAuth, requireAdmin,
  [body('firstName').notEmpty(), body('lastName').notEmpty(), body('specialty').notEmpty()],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res.status(400).json({ message: errors.array()[0].msg });

    const { firstName, lastName, specialty, description, address, city, phone, avatarUrl, price } = req.body;
    const r = db.prepare(
      `INSERT INTO doctors (firstName,lastName,specialty,description,address,city,phone,avatarUrl,price)
       VALUES (?,?,?,?,?,?,?,?,?)`
    ).run(firstName, lastName, specialty, description, address, city, phone, avatarUrl, price || 0);
    res.status(201).json({ id: r.lastInsertRowid, message: 'Médecin ajouté' });
  }
);

app.post('/api/admin/doctors/:id/slots', requireAuth, requireAdmin, (req, res) => {
  const { slots } = req.body;
  if (!Array.isArray(slots) || !slots.length)
    return res.status(400).json({ message: 'Tableau de créneaux requis' });

  const insert = db.prepare('INSERT OR IGNORE INTO time_slots (doctorId, dateTime) VALUES (?,?)');
  db.transaction((s) => s.forEach(dt => insert.run(req.params.id, dt)))(slots);
  res.json({ message: `${slots.length} créneaux ajoutés` });
});

app.put('/api/admin/doctors/:id', requireAuth, requireAdmin, (req, res) => {
  const { firstName, lastName, specialty, description, address, city, phone, avatarUrl, price, isActive } = req.body;
  db.prepare(
    `UPDATE doctors SET firstName=?,lastName=?,specialty=?,description=?,address=?,city=?,
     phone=?,avatarUrl=?,price=?,isActive=? WHERE id=?`
  ).run(firstName, lastName, specialty, description, address, city, phone, avatarUrl, price, isActive ? 1 : 0, req.params.id);
  res.json({ message: 'Mis à jour' });
});

app.delete('/api/admin/doctors/:id', requireAuth, requireAdmin, (req, res) => {
  db.prepare('UPDATE doctors SET isActive = 0 WHERE id = ?').run(req.params.id);
  res.json({ message: 'Médecin désactivé' });
});

app.get('/api/admin/stats', requireAuth, requireAdmin, (req, res) => {
  res.json({
    totalDoctors:      db.prepare('SELECT COUNT(*) as c FROM doctors WHERE isActive=1').get().c,
    totalPatients:     db.prepare("SELECT COUNT(*) as c FROM users WHERE role='patient'").get().c,
    totalAppointments: db.prepare('SELECT COUNT(*) as c FROM appointments').get().c,
    todayAppointments: db.prepare(
      "SELECT COUNT(*) as c FROM appointments WHERE dateTime LIKE ? AND status='confirmed'"
    ).get(`${new Date().toISOString().slice(0,10)}%`).c,
  });
});

// ── APPOINTMENTS ──────────────────────────────────────────────────────────────
app.post('/api/appointments', requireAuth, (req, res) => {
  const { doctorId, slotId, reason } = req.body;
  const slot   = db.prepare('SELECT * FROM time_slots WHERE id = ? AND isBooked = 0').get(slotId);
  if (!slot)   return res.status(409).json({ message: 'Créneau non disponible' });
  const doctor = db.prepare('SELECT * FROM doctors WHERE id = ?').get(doctorId);
  if (!doctor) return res.status(404).json({ message: 'Médecin introuvable' });

  const id = db.transaction(() => {
    db.prepare('UPDATE time_slots SET isBooked = 1 WHERE id = ?').run(slotId);
    return db.prepare(
      `INSERT INTO appointments (patientId,doctorId,slotId,doctorName,doctorSpecialty,dateTime,reason)
       VALUES (?,?,?,?,?,?,?)`
    ).run(
      req.user.id, doctorId, slotId,
      `Dr. ${doctor.firstName} ${doctor.lastName}`,
      doctor.specialty, slot.dateTime, reason
    ).lastInsertRowid;
  })();

  res.status(201).json({ id, message: 'Rendez-vous confirmé' });
});

app.get('/api/appointments/mine', requireAuth, (req, res) => {
  res.json(db.prepare(
    'SELECT * FROM appointments WHERE patientId = ? ORDER BY dateTime DESC'
  ).all(req.user.id));
});

app.put('/api/appointments/:id/cancel', requireAuth, (req, res) => {
  const appt = db.prepare(
    'SELECT * FROM appointments WHERE id = ? AND patientId = ?'
  ).get(req.params.id, req.user.id);
  if (!appt)                       return res.status(404).json({ message: 'Introuvable' });
  if (appt.status !== 'confirmed') return res.status(400).json({ message: 'Impossible à annuler' });

  db.transaction(() => {
    db.prepare("UPDATE appointments SET status='cancelled' WHERE id=?").run(appt.id);
    if (appt.slotId)
      db.prepare('UPDATE time_slots SET isBooked=0 WHERE id=?').run(appt.slotId);
  })();

  res.json({ message: 'Rendez-vous annulé' });
});

app.get('/health', (_, res) => res.json({ status: 'ok' }));
app.listen(PORT, () => console.log(`🚀 Carely API → port ${PORT}`));