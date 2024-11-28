const express = require('express');
const router = express.Router();
const db = require('../config/database');
const authMiddleware = require('../middleware/auth');

// Get running text by userId
router.get('/:userId', async (req, res) => {
  try {
    console.log('=== GET RUNNING TEXT ===');
    console.log('User ID:', req.params.userId);

    const [rows] = await db.execute(
      'SELECT running_text FROM users WHERE id = ?', 
      [req.params.userId]
    );

    console.log('Query result:', rows);

    if (rows.length === 0) {
      return res.status(404).json({ 
        message: 'User not found',
        userId: req.params.userId 
      });
    }

    res.json({ 
      success: true,
      running_text: rows[0].running_text || '',
      userId: req.params.userId
    });

  } catch (error) {
    console.error('Error getting running text:', error);
    res.status(500).json({ 
      message: 'Internal server error',
      error: error.message 
    });
  }
});

// Update running text (admin only)
router.post('/', authMiddleware, async (req, res) => {
  try {
    console.log('Request user:', req.user); // Debug log
    console.log('Request body:', req.body); // Debug log

    const { running_text, userId } = req.body;
    
    if (!running_text || !userId) {
      return res.status(400).json({ message: 'Running text and userId are required' });
    }

    // Update running text untuk user spesifik
    const result = await db.execute(
      'UPDATE users SET running_text = ? WHERE id = ?',
      [running_text, userId]
    );

    console.log('Update result:', result); // Debug log

    if (result[0].affectedRows === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ 
      message: 'Running text updated successfully',
      affected_rows: result[0].affectedRows 
    });
  } catch (error) {
    console.error('Error updating running text:', error);
    res.status(500).json({ 
      message: 'Internal server error',
      error: error.message 
    });
  }
});

module.exports = router; 