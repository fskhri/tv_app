const router = require('express').Router();
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const db = require('../config/database');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Konfigurasi multer untuk upload gambar
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'public/uploads';
    // Buat direktori jika belum ada
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // Limit 5MB per file
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (extname && mimetype) {
      return cb(null, true);
    } else {
      cb('Error: Images only!');
    }
  }
});

// Get all contents
router.get('/', async (req, res) => {
  try {
    const [contents] = await db.query(
      'SELECT * FROM contents WHERE is_active = true ORDER BY created_at DESC'
    );
    
    const contentsWithFullUrl = contents.map(content => ({
      ...content,
      image_urls: content.image_urls ? 
        content.image_urls.split('|').map(url => 
          `${req.protocol}://${req.get('host')}/${url}`
        ) : []
    }));
    
    res.json(contentsWithFullUrl);
  } catch (error) {
    console.error('Get contents error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Add new content with image (admin only)
router.post('/', auth, admin, upload.array('images', 10), async (req, res) => {
  try {
    const { title, description, type } = req.body;
    
    if (!title || !type) {
      return res.status(400).json({ message: 'Title and type are required' });
    }

    let image_urls = [];
    if (req.files && req.files.length > 0) {
      image_urls = req.files.map(file => `uploads/${file.filename}`);
    }

    const [result] = await db.query(
      'INSERT INTO contents (title, description, image_urls, type) VALUES (?, ?, ?, ?)',
      [title, description, image_urls.join('|'), type]
    );

    res.status(201).json({
      id: result.insertId,
      title,
      description,
      image_urls: image_urls.map(url => `${req.protocol}://${req.get('host')}/${url}`),
      type
    });
  } catch (error) {
    console.error('Add content error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Update content with image (admin only)
router.put('/:id', auth, admin, upload.array('images', 10), async (req, res) => {
  try {
    const { title, description, type, is_active, keep_images } = req.body;
    const contentId = req.params.id;
    const keepImageIndexes = keep_images ? keep_images.split(',').map(Number) : [];

    // Get existing content
    const [existingContent] = await db.query(
      'SELECT image_urls FROM contents WHERE id = ?',
      [contentId]
    );

    let existingImages = existingContent[0]?.image_urls ? 
      existingContent[0].image_urls.split('|') : [];

    // Keep selected existing images
    if (keepImageIndexes.length > 0) {
      existingImages = existingImages.filter((_, index) => 
        keepImageIndexes.includes(index)
      );
    } else {
      // Delete all existing images if none selected to keep
      existingImages.forEach(imageUrl => {
        const imagePath = path.join(__dirname, '..', 'public', imageUrl);
        if (fs.existsSync(imagePath)) {
          fs.unlinkSync(imagePath);
        }
      });
      existingImages = [];
    }

    // Add new images
    let newImageUrls = [];
    if (req.files && req.files.length > 0) {
      newImageUrls = req.files.map(file => `uploads/${file.filename}`);
    }

    // Combine kept existing images with new images
    const finalImageUrls = [...existingImages, ...newImageUrls];

    const [result] = await db.query(
      `UPDATE contents 
       SET title = ?, description = ?, image_urls = ?, type = ?, is_active = ?
       WHERE id = ?`,
      [title, description, finalImageUrls.join('|'), type, is_active, contentId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Content not found' });
    }

    res.json({ 
      message: 'Content updated successfully',
      image_urls: finalImageUrls.map(url => 
        `${req.protocol}://${req.get('host')}/${url}`
      )
    });
  } catch (error) {
    console.error('Update content error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Delete content and its image (admin only)
router.delete('/:id', auth, admin, async (req, res) => {
  try {
    const [content] = await db.query(
      'SELECT image_urls FROM contents WHERE id = ?',
      [req.params.id]
    );

    if (content[0]?.image_urls) {
      const imageUrls = content[0].image_urls.split('|');
      imageUrls.forEach(imageUrl => {
        const imagePath = path.join(__dirname, '..', 'public', imageUrl);
        if (fs.existsSync(imagePath)) {
          fs.unlinkSync(imagePath);
        }
      });
    }

    const [result] = await db.query(
      'DELETE FROM contents WHERE id = ?',
      [req.params.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Content not found' });
    }

    res.json({ message: 'Content deleted successfully' });
  } catch (error) {
    console.error('Delete content error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get content by ID
router.get('/:id', async (req, res) => {
  try {
    const [contents] = await db.query(
      'SELECT * FROM contents WHERE id = ?',
      [req.params.id]
    );

    if (contents.length === 0) {
      return res.status(404).json({ message: 'Content not found' });
    }

    const content = {
      ...contents[0],
      image_urls: contents[0].image_urls ? 
        contents[0].image_urls.split('|').map(url => 
          `${req.protocol}://${req.get('host')}/${url}`
        ) : []
    };

    res.json(content);
  } catch (error) {
    console.error('Get content error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Update running text (admin only)
router.put('/running-text/:userId', auth, admin, async (req, res) => {
  try {
    const { running_text } = req.body;
    const userId = req.params.userId;

    const [result] = await db.query(
      'UPDATE users SET running_text = ? WHERE id = ?',
      [running_text, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ message: 'Running text updated successfully' });
  } catch (error) {
    console.error('Update running text error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get running text
router.get('/running-text/:userId', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT running_text FROM users WHERE id = ?',
      [req.params.userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ running_text: rows[0].running_text });
  } catch (error) {
    console.error('Get running text error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router; 