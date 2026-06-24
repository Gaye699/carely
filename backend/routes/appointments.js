const express = require("express");

module.exports = function createAppointmentsRouter(db, authenticate) {
  const router = express.Router();
  router.use(authenticate);

  router.post("/appointments", (req, res) => {
    const { doctorId, slotId, reason } = req.body;

    if (!doctorId || !slotId) {
      return res.status(400).json({ error: "doctorId et slotId sont requis" });
    }

    const slot = db
      .prepare("SELECT * FROM time_slots WHERE id = ? AND isBooked = 0")
      .get(slotId);
    if (!slot)
      return res
        .status(409)
        .json({ error: "Créneau indisponible ou déjà réservé" });

    const doctor = db
      .prepare("SELECT * FROM doctors WHERE id = ? AND isActive = 1")
      .get(doctorId);
    if (!doctor) return res.status(404).json({ error: "Médecin introuvable" });

    const book = db.transaction(() => {
      db.prepare("UPDATE time_slots SET isBooked = 1 WHERE id = ?").run(slotId);
      return db
        .prepare(
          `INSERT INTO appointments
            (patientId, doctorId, slotId, doctorName, doctorSpecialty, dateTime, reason)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
        )
        .run(
          req.user.id,
          doctorId,
          slotId,
          `${doctor.firstName} ${doctor.lastName}`,
          doctor.specialty,
          slot.dateTime,
          reason || null,
        );
    });

    const result = book();
    const appointment = db
      .prepare("SELECT * FROM appointments WHERE id = ?")
      .get(result.lastInsertRowid);
    res.status(201).json(appointment);
  });

  router.get("/appointments", (req, res) => {
    const appointments = db
      .prepare(
        "SELECT * FROM appointments WHERE patientId = ? ORDER BY dateTime DESC",
      )
      .all(req.user.id);
    res.json(appointments);
  });

  router.delete("/appointments/:id", (req, res) => {
    const appointment = db
      .prepare("SELECT * FROM appointments WHERE id = ? AND patientId = ?")
      .get(req.params.id, req.user.id);

    if (!appointment)
      return res.status(404).json({ error: "Rendez-vous introuvable" });
    if (appointment.status !== "confirmed") {
      return res
        .status(400)
        .json({ error: "Ce rendez-vous ne peut plus être annulé" });
    }

    db.transaction(() => {
      db.prepare("UPDATE appointments SET status = ? WHERE id = ?").run(
        "cancelled",
        appointment.id,
      );
      if (appointment.slotId) {
        db.prepare("UPDATE time_slots SET isBooked = 0 WHERE id = ?").run(
          appointment.slotId,
        );
      }
    })();

    res.json({ message: "Rendez-vous annulé" });
  });

  return router;
};
