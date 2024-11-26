const router = require('express').Router();
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');

// Get all users
router.get('/', auth, admin, async (req, res) => {
  try {
    const [rows] = await db.query('SELECT id, username, role, is_active FROM users');
    res.json(rows.map(user => ({
      ...user,
      isActive: user.is_active === 1
    })));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create user
router.post('/', auth, admin, async (req, res) => {
  try {
    const { username, password, role } = req.body;
    
    // Validasi input
    if (!username || !password || !role) {
      return res.status(400).json({ 
        message: 'Username, password, and role are required' 
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Generate ID menggunakan username
    const userId = `user-${username.toLowerCase()}`; // Menggunakan username sebagai bagian dari ID

    // Create user object
    const user = {
      id: userId,
      username,
      password: hashedPassword,
      role,
      is_active: true
    };

    // Check if username already exists
    const [existingUsers] = await db.query(
      'SELECT * FROM users WHERE username = ?',
      [username]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({
        message: 'Username already exists'
      });
    }

    // Insert user to database
    await db.query('INSERT INTO users SET ?', user);

    // Return user data without password
    const { password: _, ...userWithoutPassword } = user;
    res.status(201).json(userWithoutPassword);
  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Update user
router.put('/:id', auth, admin, async (req, res) => {
  try {
    const { isActive } = req.body;
    const [result] = await db.query(
      'UPDATE users SET is_active = ? WHERE id = ?',
      [isActive, req.params.id]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json({ message: 'User updated successfully' });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Delete user
router.delete('/:id', auth, admin, async (req, res) => {
  try {
    const [result] = await db.query('DELETE FROM users WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router; 