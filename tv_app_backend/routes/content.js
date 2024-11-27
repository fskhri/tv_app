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
    const dir = path.join(__dirname, '..', 'public', 'uploads');
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    console.log('Saving file to:', dir);
    cb(null, dir);
  },
  filename: function(req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const filename = 'image-' + uniqueSuffix + path.extname(file.originalname);
    console.log('Generated filename:', filename);
    cb(null, filename);
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

// Buat instance multer untuk single upload
const singleUpload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB
  }
});

// Buat instance multer untuk multiple upload
const multipleUpload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB
  }
}).array('images', 10);

const baseUrl = 'https://0g7d00kv-3000.asse.devtunnels.ms';

// POST /content - Create new content (multiple images)
router.post('/', auth, (req, res) => {
  multipleUpload(req, res, async function(err) {
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

      const [result] = await db.query(
        'INSERT INTO contents (user_id, title, description, image_urls, type) VALUES (?, ?, ?, ?, ?)',
        [userId, title, description, imageUrls.join('|'), 'image']
      );

      res.status(200).json({
        success: true,
        message: 'Content uploaded successfully',
        data: {
          id: result.insertId,
          title,
          description,
          imageUrls: imageUrls.map(url => `${baseUrl}/${url}`)
        }
      });
    } catch (error) {
      console.error('Database error:', error);
      res.status(500).json({
        success: false,
        message: 'Error saving content to database',
        error: error.message
      });
    }
  });
});

// POST /content/upload - Upload single image
router.post('/upload', singleUpload.single('content'), async (req, res) => {
  try {
    const { title, description } = req.body;
    const imageFile = req.file;

    if (!imageFile) {
      return res.status(400).json({ message: 'File gambar harus disertakan' });
    }

    // Simpan informasi konten ke database
    const [result] = await db.query(
      `INSERT INTO contents (
        title, 
        description,
        image_urls,
        type
      ) VALUES (?, ?, ?, ?)`,
      [
        title,
        description,
        `uploads/${imageFile.filename}`,
        'image'
      ]
    );

    res.status(201).json({ 
      message: 'Gambar berhasil diupload',
      content: {
        id: result.insertId,
        title,
        description,
        imageUrl: `${baseUrl}/uploads/${imageFile.filename}`
      }
    });

  } catch (error) {
    console.error('Error uploading image:', error);
    res.status(500).json({ 
      message: 'Gagal mengupload gambar',
      error: error.message 
    });
  }
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
      image_urls_full: content.image_urls 
        ? content.image_urls.split('|').map(url => 
            `${baseUrl}/${url}`
          )
        : []
    }));

    console.log(`Found ${transformedContents.length} contents for user ${userId}`);

    console.log('Generated image URLs:', transformedContents.map(content => ({
      original: content.image_urls,
      full: content.image_urls_full
    })));

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

// GET /content - Get all contents
router.get('/', auth, async (req, res) => {
  try {
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
      WHERE is_active = true
      ORDER BY created_at DESC`
    );

    const transformedContents = contents.map(content => ({
      ...content,
      image_urls: content.image_urls ? content.image_urls.split('|') : [],
      image_urls_full: content.image_urls 
        ? content.image_urls.split('|').map(url => 
            `${baseUrl}/${url}`
          )
        : []
    }));

    console.log('Transformed contents:', transformedContents.map(content => ({
      id: content.id,
      urls: content.image_urls_full
    })));

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

// GET /content/images/:userId - Get uploaded images by user ID
router.get('/images/:userId', auth, async (req, res) => {
  try {
    const userId = req.params.userId;
    console.log('Fetching images for userId:', userId);

    const [images] = await db.query(
      `SELECT 
        id,
        title,
        description,
        image_urls,
        created_at
      FROM contents 
      WHERE user_id = ? 
      AND type = 'image'
      AND is_active = true
      ORDER BY created_at DESC`,
      [userId]
    );

    // Transform data dan tambahkan full URL untuk gambar
    const transformedImages = images.map(image => ({
      id: image.id,
      title: image.title,
      description: image.description,
      uploadDate: image.created_at,
      imageUrl: image.image_urls ? `${baseUrl}/${image.image_urls}` : null,
      thumbnailUrl: image.image_urls ? `${baseUrl}/${image.image_urls}` : null
    }));

    console.log(`Found ${transformedImages.length} images for user ${userId}`);

    res.json({
      success: true,
      data: transformedImages
    });

  } catch (error) {
    console.error('Error fetching images:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching images',
      error: error.message
    });
  }
});

// Update endpoint untuk menghapus gambar
router.delete('/images/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Dapatkan informasi gambar dari database
    const [image] = await db.query(
      'SELECT image_urls FROM contents WHERE id = ? AND type = "image"', 
      [id]
    );
    
    if (!image) {
      return res.status(404).json({ 
        success: false, 
        message: 'Image not found' 
      });
    }

    // Hapus file fisik jika ada
    if (image.image_urls) {
      const filePath = path.join(__dirname, '..', 'public', image.image_urls);
      if (fs.existsSync(filePath)) {
        try {
          fs.unlinkSync(filePath);
          console.log('File fisik berhasil dihapus:', filePath);
        } catch (err) {
          console.error('Error menghapus file fisik:', err);
          // Lanjutkan proses meskipun file fisik gagal dihapus
        }
      }
    }

    // Hapus record dari database
    const [result] = await db.query(
      'DELETE FROM contents WHERE id = ? AND type = "image"', 
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Image not found or already deleted'
      });
    }

    res.json({ 
      success: true, 
      message: 'Image deleted successfully' 
    });
  } catch (error) {
    console.error('Error deleting image:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to delete image',
      error: error.message 
    });
  }
});

module.exports = router; 