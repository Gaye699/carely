const express = require("express");

module.exports = function createDoctorsRouter(db, authenticate, requireAdmin) {
  const router = express.Router();

  router.get("/doctors", authenticate, (req, res) => {
    const { specialty, search } = req.query;
    let query = "SELECT * FROM doctors WHERE isActive = 1";
    const params = [];

    if (specialty) {
      query += " AND specialty = ?";
      params.push(specialty);
    }
    if (search) {
      query +=
        " AND (firstName LIKE ? OR lastName LIKE ? OR specialty LIKE ? OR city LIKE ?)";
      const like = `%${search}%`;
      params.push(like, like, like, like);
    }

    query += " ORDER BY rating DESC";
    res.json(db.prepare(query).all(...params));
  });

  router.get("/doctors/:id", authenticate, (req, res) => {
    const doctor = db
      .prepare("SELECT * FROM doctors WHERE id = ? AND isActive = 1")
      .get(req.params.id);
    if (!doctor) return res.status(404).json({ error: "Médecin introuvable" });
    res.json(doctor);
  });

  router.get("/doctors/:id/slots", authenticate, (req, res) => {
    const { date } = req.query;
    let query = `
      SELECT * FROM time_slots
      WHERE doctorId = ? AND isBooked = 0 AND dateTime > datetime('now')
    `;
    const params = [req.params.id];

    if (date) {
      query += " AND date(dateTime) = date(?)";
      params.push(date);
    }

    query += " ORDER BY dateTime ASC";
    res.json(db.prepare(query).all(...params));
  });

  router.post("/doctors/:id/slots", authenticate, requireAdmin, (req, res) => {
    const { slots } = req.body;
    if (!Array.isArray(slots) || slots.length === 0) {
      return res
        .status(400)
        .json({
          error: "slots doit être un tableau non vide de dates ISO 8601",
        });
    }

    const insert = db.prepare(
      "INSERT OR IGNORE INTO time_slots (doctorId, dateTime) VALUES (?, ?)",
    );
    db.transaction(() =>
      slots.forEach((dt) => insert.run(req.params.id, dt)),
    )();

    res.status(201).json({ message: `${slots.length} créneau(x) ajouté(s)` });
  });

  return router;
};
