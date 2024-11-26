const router = require('express').Router();
const auth = require('../middleware/auth');
const db = require('../config/database');
const cities = require('../data/indonesia-cities');
const { PrayerTimes, Coordinates, CalculationMethod } = require('adhan');

// Endpoint untuk sinkronisasi data
router.post('/', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { prayerSchedules } = req.body;

    // Simpan data sinkronisasi ke database
    await db.query('BEGIN'); // Mulai transaksi

    // Hapus data lama untuk user tersebut
    await db.query(
      'DELETE FROM prayer_schedules WHERE user_id = ?',
      [userId]
    );

    // Masukkan data baru
    for (const schedule of prayerSchedules) {
      await db.query(
        'INSERT INTO prayer_schedules (user_id, prayer_name, time, date) VALUES (?, ?, ?, ?)',
        [userId, schedule.prayerName, schedule.time, schedule.date]
      );
    }

    await db.query('COMMIT'); // Commit transaksi

    // Ambil data terbaru untuk dikirim kembali ke client
    const [updatedSchedules] = await db.query(
      'SELECT * FROM prayer_schedules WHERE user_id = ?',
      [userId]
    );

    res.json({
      success: true,
      data: updatedSchedules,
      lastSync: new Date().toISOString()
    });

  } catch (error) {
    await db.query('ROLLBACK'); // Rollback jika terjadi error
    console.error('Sync error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// Endpoint untuk mengambil data terakhir dari server
router.get('/latest', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const [schedules] = await db.query(
      'SELECT * FROM prayer_schedules WHERE user_id = ? ORDER BY date DESC',
      [userId]
    );

    res.json({
      success: true,
      data: schedules
    });
  } catch (error) {
    console.error('Get latest data error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// Endpoint untuk mendapatkan list jadwal sholat
router.get('/list', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { date } = req.query; // Opsional: filter berdasarkan tanggal
    
    let query = 'SELECT * FROM prayer_schedules WHERE user_id = ?';
    let queryParams = [userId];

    // Jika ada parameter tanggal, tambahkan ke query
    if (date) {
      query += ' AND date = ?';
      queryParams.push(date);
    }

    query += ' ORDER BY time ASC';

    const [schedules] = await db.query(query, queryParams);

    // Grouping jadwal berdasarkan tanggal
    const groupedSchedules = schedules.reduce((acc, schedule) => {
      if (!acc[schedule.date]) {
        acc[schedule.date] = [];
      }
      acc[schedule.date].push({
        id: schedule.id,
        prayerName: schedule.prayer_name,
        time: schedule.time,
        date: schedule.date
      });
      return acc;
    }, {});

    res.json({
      success: true,
      data: groupedSchedules,
      total: schedules.length
    });

  } catch (error) {
    console.error('List prayer schedules error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// Endpoint untuk mendapatkan jadwal sholat hari ini
router.get('/today', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const today = new Date().toISOString().split('T')[0]; // Format: YYYY-MM-DD
    
    const [schedules] = await db.query(
      'SELECT * FROM prayer_schedules WHERE user_id = ? AND date = ? ORDER BY time ASC',
      [userId, today]
    );

    res.json({
      success: true,
      data: schedules.map(schedule => ({
        id: schedule.id,
        prayerName: schedule.prayer_name,
        time: schedule.time,
        date: schedule.date
      }))
    });

  } catch (error) {
    console.error('Today prayer schedules error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// Endpoint untuk mendapatkan jadwal sholat berdasarkan range tanggal
router.get('/range', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'Start date and end date are required'
      });
    }

    const [schedules] = await db.query(
      'SELECT * FROM prayer_schedules WHERE user_id = ? AND date BETWEEN ? AND ? ORDER BY date ASC, time ASC',
      [userId, startDate, endDate]
    );

    // Grouping berdasarkan tanggal
    const groupedSchedules = schedules.reduce((acc, schedule) => {
      if (!acc[schedule.date]) {
        acc[schedule.date] = [];
      }
      acc[schedule.date].push({
        id: schedule.id,
        prayerName: schedule.prayer_name,
        time: schedule.time,
        date: schedule.date
      });
      return acc;
    }, {});

    res.json({
      success: true,
      data: groupedSchedules,
      total: schedules.length
    });

  } catch (error) {
    console.error('Range prayer schedules error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// Endpoint untuk generate jadwal sholat setahun
router.post('/generate-yearly-schedule', auth, async (req, res) => {
  try {
    await db.query('BEGIN');

    // Hapus data lama
    await db.query('DELETE FROM prayer_schedules');

    const year = new Date().getFullYear();
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year + 1, 0, 0);

    for (const province of cities) {
      for (const city of province.cities) {
        const coordinates = new Coordinates(city.lat, city.lon);
        const params = CalculationMethod.MUSLIM_WORLD_LEAGUE();
        
        let currentDate = new Date(startDate);
        
        while (currentDate <= endDate) {
          const prayerTimes = new PrayerTimes(coordinates, currentDate, params);
          
          const prayers = [
            { name: 'Fajr', time: prayerTimes.fajr },
            { name: 'Dhuhr', time: prayerTimes.dhuhr },
            { name: 'Asr', time: prayerTimes.asr },
            { name: 'Maghrib', time: prayerTimes.maghrib },
            { name: 'Isha', time: prayerTimes.isha }
          ];

          for (const prayer of prayers) {
            await db.query(
              `INSERT INTO prayer_schedules 
               (city, province, prayer_name, time, date) 
               VALUES (?, ?, ?, ?, ?)`,
              [
                city.name,
                province.province,
                prayer.name,
                prayer.time.toLocaleTimeString('en-US', { hour12: false }),
                currentDate.toISOString().split('T')[0]
              ]
            );
          }

          currentDate.setDate(currentDate.getDate() + 1);
        }
      }
    }

    await db.query('COMMIT');

    res.json({
      success: true,
      message: 'Yearly prayer schedules generated successfully'
    });

  } catch (error) {
    await db.query('ROLLBACK');
    console.error('Generate schedule error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Update endpoint get prayer schedules untuk include kota
router.get('/schedules/:city', auth, async (req, res) => {
  try {
    const { city } = req.params;
    const { date } = req.query;
    
    let query = 'SELECT * FROM prayer_schedules WHERE city = ?';
    let params = [city];

    if (date) {
      query += ' AND date = ?';
      params.push(date);
    }

    query += ' ORDER BY date ASC, time ASC';

    const [schedules] = await db.query(query, params);

    res.json({
      success: true,
      data: schedules
    });

  } catch (error) {
    console.error('Get schedules error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Endpoint untuk mendapatkan daftar provinsi dan kota
router.get('/locations', auth, async (req, res) => {
  try {
    res.json({
      success: true,
      data: cities // dari indonesia-cities.js
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Endpoint untuk mengatur lokasi user
router.post('/set-location', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { city, province } = req.body;

    // Validasi kota dan provinsi
    const isValidLocation = cities.some(p => 
      p.province === province && 
      p.cities.some(c => c.name === city)
    );

    if (!isValidLocation) {
      return res.status(400).json({
        success: false,
        message: 'Invalid city or province'
      });
    }

    // Update atau insert lokasi user
    await db.query(`
      INSERT INTO user_locations (user_id, city, province) 
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE 
      city = VALUES(city),
      province = VALUES(province)
    `, [userId, city, province]);

    res.json({
      success: true,
      message: 'Location updated successfully'
    });

  } catch (error) {
    console.error('Set location error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Endpoint untuk mendapatkan lokasi user
router.get('/user-location', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const [locations] = await db.query(
      'SELECT city, province FROM user_locations WHERE user_id = ?',
      [userId]
    );

    if (locations.length === 0) {
      return res.json({
        success: true,
        data: {
          city: "Jakarta Pusat", // Default location
          province: "DKI Jakarta"
        }
      });
    }

    res.json({
      success: true,
      data: locations[0]
    });

  } catch (error) {
    console.error('Get user location error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router; 