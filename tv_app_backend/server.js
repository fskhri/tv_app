const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const db = require('./config/database');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// Create tables if not exist
async function createTables() {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(50) PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        role ENUM('admin', 'user') DEFAULT 'user',
        is_active BOOLEAN DEFAULT true
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
const userLocationsRouter = require('./routes/user_locations');
app.use('/api/user-locations', userLocationsRouter);

// Test route
app.get('/test', (req, res) => {
  res.json({ message: 'Server is working!' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on port ${port}`);
}); 