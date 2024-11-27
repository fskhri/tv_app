const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const db = require('./config/database');
require('dotenv').config();
const path = require('path');
const fs = require('fs');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  exposedHeaders: ['Content-Length', 'Content-Type'],
  credentials: true,
}));
app.use(express.json());
app.use(express.static('public'));
app.use('/uploads', express.static(path.join(__dirname, 'public', 'uploads')));

// Pastikan folder uploads ada dengan permission yang benar
const uploadDir = path.join(__dirname, 'public', 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
  // Set permissions jika diperlukan
  fs.chmodSync(uploadDir, '755');
}

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'public', 'uploads')));

// Tambahkan middleware untuk debugging
app.use('/uploads', (req, res, next) => {
  const filePath = path.join(__dirname, 'public', 'uploads', req.url);
  console.log('Request URL:', req.url);
  console.log('Full file path:', filePath);
  console.log('File exists:', fs.existsSync(filePath));
  
  // Log file permissions
  try {
    const stats = fs.statSync(filePath);
    console.log('File permissions:', stats.mode.toString(8));
  } catch (err) {
    console.log('Error checking file:', err);
  }
  
  next();
});

// Tambahkan error handler untuk static files
app.use((err, req, res, next) => {
  console.error('Static file error:', err);
  res.status(500).send('Error serving static file');
});

// Tambahkan route khusus untuk mengecek file
app.get('/check-file/:filename', (req, res) => {
  const filePath = path.join(__dirname, 'public', 'uploads', req.params.filename);
  
  if (fs.existsSync(filePath)) {
    res.json({
      exists: true,
      stats: fs.statSync(filePath),
      path: filePath
    });
  } else {
    res.json({
      exists: false,
      searchedPath: filePath
    });
  }
});

// Tambahkan CORS header untuk static files
app.use('/uploads', (req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

// Create tables if not exist
async function createTables() {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(50) PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        role ENUM('admin', 'user') DEFAULT 'user',
        is_active BOOLEAN DEFAULT true,
        running_text TEXT,
        content_enabled BOOLEAN DEFAULT true
      )
    `);
    console.log('Users table ready');
    await createAdminUser();
    await db.query(`
      CREATE TABLE IF NOT EXISTS prayer_schedules (
        id INT AUTO_INCREMENT PRIMARY KEY,
        city VARCHAR(100) NOT NULL,
        province VARCHAR(100) NOT NULL,
        prayer_name VARCHAR(50) NOT NULL,
        time VARCHAR(10) NOT NULL,
        date VARCHAR(10) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_city (city),
        INDEX idx_date (date)
      )
    `);
    console.log('Prayer schedules table ready');
    await db.query(`
      CREATE TABLE IF NOT EXISTS user_locations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        city VARCHAR(100) NOT NULL,
        province VARCHAR(100) NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        UNIQUE KEY unique_user (user_id)
      )
    `);
    console.log('User locations table ready');
    await db.query(`
      CREATE TABLE IF NOT EXISTS contents (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        image_urls TEXT,
        type ENUM('image', 'text', 'both') NOT NULL,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      ) ENGINE=InnoDB
    `);
    console.log('Contents table created');
  } catch (err) {
    console.error('Error creating table:', err);
  }
}

// Create default admin user
async function createAdminUser() {
  try {
    const [rows] = await db.query('SELECT * FROM users WHERE username = ?', ['admin']);
    
    if (rows.length === 0) {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      const adminUser = {
        id: 'admin-1',
        username: 'admin',
        password: hashedPassword,
        role: 'admin',
        is_active: true
      };

      await db.query('INSERT INTO users SET ?', adminUser);
      console.log('Admin user created successfully');
    }
  } catch (err) {
    console.error('Error creating admin:', err);
  }
}

// Initialize database
createTables();

// Add request logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  console.log('Request body:', req.body);
  next();
});

// Routes
app.use('/auth', require('./routes/auth'));
app.use('/users', require('./routes/users'));
app.use('/sync', require('./routes/sync'));
app.use('/user-locations', require('./routes/user_locations'));
app.use('/content', require('./routes/content'));

// Test route
app.get('/test', (req, res) => {
  res.json({ message: 'Server is working!' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on port ${port}`);
}); 