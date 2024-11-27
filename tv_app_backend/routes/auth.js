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
    console.log('=== LOGIN ATTEMPT ===');
    console.log('Username:', username);
    console.log('Time:', new Date().toISOString());

    const [rows] = await db.query(
      'SELECT * FROM users WHERE username = ?',
      [username]
    );

    if (rows.length === 0) {
      console.log('Login failed: User not found');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = rows[0];
    console.log('User found:', {
      id: user.id,
      username: user.username,
      role: user.role,
      isActive: user.is_active === 1
    });

    const isMatch = await bcrypt.compare(password, user.password);
    console.log('Password match:', isMatch);

    if (!isMatch) {
      console.log('Login failed: Invalid password');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Setelah login berhasil, ambil data lokasi user
    const [userLocations] = await db.query(
      'SELECT * FROM user_locations WHERE user_id = ?',
      [user.id]
    );
    console.log('User location data:', userLocations[0] || 'No location set');

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );
    console.log('Token generated successfully');

    // Log response data
    const responseData = {
      token,
      user: {
        id: user.id,
        username: user.username,
        role: user.role,
        isActive: user.is_active === 1
      },
      location: userLocations[0] || null
    };
    console.log('Login response data:', responseData);
    console.log('=== LOGIN SUCCESSFUL ===');

    res.json(responseData);
  } catch (error) {
    console.error('=== LOGIN ERROR ===');
    console.error('Error details:', error);
    console.error('Stack trace:', error.stack);
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