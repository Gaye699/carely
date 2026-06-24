const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

module.exports = function createAuthRouter(db, JWT_SECRET, loginLimiter) {
  const router = express.Router();

  router.post("/auth/register", async (req, res) => {
    const { firstName, lastName, email, password, phone } = req.body;

    if (!firstName || !lastName || !email || !password) {
      return res
        .status(400)
        .json({ error: "Tous les champs obligatoires doivent être remplis" });
    }
    if (password.length < 8) {
      return res
        .status(400)
        .json({ error: "Le mot de passe doit contenir au moins 8 caractères" });
    }

    const existing = db
      .prepare("SELECT id FROM users WHERE email = ?")
      .get(email);
    if (existing) {
      return res.status(409).json({ error: "Email déjà utilisé" });
    }

    const hashed = await bcrypt.hash(password, 12);
    const result = db
      .prepare(
        "INSERT INTO users (firstName, lastName, email, password, phone) VALUES (?, ?, ?, ?, ?)",
      )
      .run(firstName, lastName, email, hashed, phone || null);

    const token = jwt.sign(
      { id: result.lastInsertRowid, email, role: "patient" },
      JWT_SECRET,
      { expiresIn: "7d" },
    );

    res.status(201).json({
      token,
      user: {
        id: result.lastInsertRowid,
        firstName,
        lastName,
        email,
        role: "patient",
      },
    });
  });

  router.post("/auth/login", loginLimiter, async (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: "Email et mot de passe requis" });
    }

    const user = db.prepare("SELECT * FROM users WHERE email = ?").get(email);
    const invalid = () =>
      res.status(401).json({ error: "Identifiants invalides" });

    if (!user) return invalid();
    const match = await bcrypt.compare(password, user.password);
    if (!match) return invalid();

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: "7d" },
    );

    const { password: _pwd, ...safeUser } = user;
    res.json({ token, user: safeUser });
  });

  return router;
};
