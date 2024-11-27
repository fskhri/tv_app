const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Import routes
const userLocationsRouter = require('./routes/user_locations');

// Register routes
app.use('/user-locations', userLocationsRouter);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        success: false,
        message: 'Terjadi kesalahan pada server'
    });
});

// Handle 404
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint tidak ditemukan'
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server berjalan di port ${PORT}`);
});

module.exports = app; 