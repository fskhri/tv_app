const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const express = require('express');

// Middleware dan model yang diperlukan
const authMiddleware = require('../middleware/auth');
const UserLocation = require('../models/UserLocation');

router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    console.log('Login attempt:', { username });

    const [rows] = await db.query(
      'SELECT * FROM users WHERE username = ?',
      [username]
    );

    if (rows.length === 0) {
      console.log('User not found');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = rows[0];
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        role: user.role,
        isActive: user.is_active === 1
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Tambahkan lokasi pengguna
router.post('/user-locations', authMiddleware, async (req, res) => {
  try {
    const { userId, province, city } = req.body;
    const newUserLocation = new UserLocation({ userId, province, city });
    await newUserLocation.save();
    res.status(201).send(newUserLocation);
  } catch (error) {
    console.error('Error adding user location:', error);
    res.status(400).send({ error: 'Failed to add user location' });
  }
});

module.exports = router; 