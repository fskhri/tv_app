const express = require('express');
const router = express.Router();
const db = require('../config/database');

// Endpoint untuk mendapatkan lokasi pengguna
router.get('/', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM user_locations');
        console.log('Fetched user locations:', rows);
        res.json(rows);
    } catch (err) {
        res.status(500).send('Error retrieving user locations');
    }
});

// Endpoint untuk menambahkan lokasi pengguna
router.post('/', async (req, res) => {
    console.log('Creating new location, request body:', req.body);
    const { user_id, city, province } = req.body;
    
    try {
        const [result] = await db.query(
            'INSERT INTO user_locations (user_id, city, province) VALUES (?, ?, ?)',
            [user_id, city, province]
        );
        
        console.log('Insert result:', result);
        
        res.status(201).json({
            message: 'Location added successfully',
            id: result.insertId,
            user_id,
            city,
            province
        });
    } catch (err) {
        console.error('Error adding user location:', err);
        res.status(500).json({ 
            message: 'Error adding user location',
            error: err.message 
        });
    }
});

// Endpoint untuk memperbarui lokasi pengguna
router.post('/update-location', async (req, res) => {
    console.log('Received update request:', req.body);
    try {
        const { userId, province, city } = req.body;
        
        // Validasi input
        if (!userId || !province || !city) {
            console.log('Validation failed:', { userId, province, city });
            return res.status(400).json({ 
                success: false, 
                message: 'userId, province, dan city harus diisi' 
            });
        }

        // Cek apakah lokasi sudah ada
        const [existingLocation] = await db.query(
            'SELECT * FROM user_locations WHERE user_id = ?',
            [userId]
        );

        let result;
        if (existingLocation.length > 0) {
            // Update existing location
            [result] = await db.query(
                'UPDATE user_locations SET province = ?, city = ? WHERE user_id = ?',
                [province, city, userId]
            );
        } else {
            // Insert new location
            [result] = await db.query(
                'INSERT INTO user_locations (user_id, province, city) VALUES (?, ?, ?)',
                [userId, province, city]
            );
        }

        console.log('Database operation result:', result);

        return res.json({ 
            success: true, 
            message: 'Lokasi berhasil diperbarui' 
        });
    } catch (error) {
        console.error('Error updating location:', error);
        return res.status(500).json({ 
            success: false, 
            message: 'Gagal memperbarui lokasi: ' + error.message 
        });
    }
});

// Endpoint untuk menghapus lokasi pengguna
router.delete('/:id', async (req, res) => {
    const { id } = req.params;
    try {
        await db.query('DELETE FROM user_locations WHERE id = ?', [id]);
        res.send(`Lokasi pengguna dengan ID ${id} dihapus`);
    } catch (err) {
        res.status(500).send('Error deleting user location');
    }
});

// Endpoint untuk mendapatkan user_id berdasarkan username
router.get('/user-id/:username', async (req, res) => {
    const { username } = req.params;
    try {
        const [rows] = await db.query(`
            SELECT u.id as user_id 
            FROM users u
            WHERE u.username = ?
        `, [username]);
        
        if (rows.length > 0) {
            res.json({ user_id: rows[0].user_id });
        } else {
            res.status(404).send('User not found');
        }
    } catch (err) {
        res.status(500).send('Error retrieving user ID');
    }
});

// GET user location by userId
router.get('/api/user-locations/:userId', async (req, res) => {
  try {
    const userLocation = await UserLocation.findOne({ user_id: req.params.userId });
    if (userLocation) {
      res.json(userLocation);
    } else {
      res.status(404).json({ message: 'Location not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PUT update user location
router.put('/api/user-locations/:userId', async (req, res) => {
  try {
    const { province, city } = req.body;
    const userLocation = await UserLocation.findOneAndUpdate(
      { user_id: req.params.userId },
      { province, city },
      { new: true }
    );
    if (userLocation) {
      res.json(userLocation);
    } else {
      res.status(404).json({ message: 'Location not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Endpoint untuk mengecek lokasi pengguna berdasarkan user_id
router.get('/check/:userId', async (req, res) => {
    console.log('Checking location for userId:', req.params.userId);
    try {
        const [rows] = await db.query(
            'SELECT * FROM user_locations WHERE user_id = ?', 
            [req.params.userId]
        );
        console.log('Check result:', rows);
        
        if (rows.length > 0) {
            res.json(rows[0]);
        } else {
            res.status(404).json({ message: 'Location not found' });
        }
    } catch (err) {
        console.error('Error checking user location:', err);
        res.status(500).json({ 
            message: 'Error checking user location',
            error: err.message 
        });
    }
});

module.exports = router;