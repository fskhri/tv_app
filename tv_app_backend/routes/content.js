const router = require('express').Router();
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const db = require('../config/database');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Konfigurasi multer untuk upload gambar
const storage = multer.diskStorage({
  destination: function(req, file, cb) {
    const dir = 'public/uploads';
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: function(req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'image-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  const allowedMimes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/octet-stream'
  ];

  console.log('File upload attempt:', {
    fieldname: file.fieldname,
    originalname: file.originalname,
    mimetype: file.mimetype
  });

  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`File type ${file.mimetype} not allowed`));
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024
  }
}).array('images', 10);

// POST /content - Create new content
router.post('/', auth, (req, res) => {
  upload(req, res, async function(err) {
    console.log('Upload request received');
    console.log('Files:', req.files);
    console.log('Body:', req.body);

    if (err instanceof multer.MulterError) {
      console.error('Multer error:', err);
      return res.status(400).json({
        success: false,
        message: `Upload error: ${err.message}`
      });
    } else if (err) {
      console.error('Unknown error:', err);
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }

    try {
      const { userId, title, description } = req.body;
      console.log('Attempting to save content with:', { userId, title, description });

      if (!userId || !title) {
        return res.status(400).json({
          success: false,
          message: 'userId and title are required'
        });
      }

      let imageUrls = [];
      if (req.files && req.files.length > 0) {
        imageUrls = req.files.map(file => `uploads/${file.filename}`);
        console.log('Image URLs:', imageUrls);
      }

      console.log('Executing database query with values:', {
        userId,
        title,
        description,
        imageUrls: imageUrls.join('|'),
        type: 'image'
      });

      const [result] = await db.query(
        'INSERT INTO contents (user_id, title, description, image_urls, type) VALUES (?, ?, ?, ?, ?)',
        [userId, title, description, imageUrls.join('|'), 'image']
      );

      console.log('Content saved to database:', result);

      res.status(200).json({
        success: true,
        message: 'Content uploaded successfully',
        data: {
          id: result.insertId,
          title,
          description,
          imageUrls: imageUrls.map(url => `${req.protocol}://${req.get('host')}/${url}`)
        }
      });
    } catch (error) {
      console.error('Database error details:', {
        code: error.code,
        errno: error.errno,
        sqlMessage: error.sqlMessage,
        sql: error.sql
      });
      
      res.status(500).json({
        success: false,
        message: 'Error saving content to database',
        error: error.sqlMessage
      });
    }
  });
});

// GET /content/:userId - Get content by user ID
router.get('/:userId', auth, async (req, res) => {
  try {
    const userId = req.params.userId;
    console.log('Fetching content for userId:', userId);

    const [contents] = await db.query(
      `SELECT 
        id,
        user_id,
        title,
        description,
        image_urls,
        type,
        is_active,
        created_at,
        updated_at
      FROM contents 
      WHERE user_id = ?
      ORDER BY created_at DESC`,
      [userId]
    );

    // Transform image_urls from pipe-separated string to array
    const transformedContents = contents.map(content => ({
      ...content,
      image_urls: content.image_urls ? content.image_urls.split('|') : [],
      // Add full URL for each image
      image_urls_full: content.image_urls 
        ? content.image_urls.split('|').map(url => 
            `${req.protocol}://${req.get('host')}/${url}`
          )
        : []
    }));

    console.log(`Found ${transformedContents.length} contents for user ${userId}`);

    res.json({
      success: true,
      data: transformedContents
    });

  } catch (error) {
    console.error('Error fetching contents:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching contents',
      error: error.message
    });
  }
});

module.exports = router; 