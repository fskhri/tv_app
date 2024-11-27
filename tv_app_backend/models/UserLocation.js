const mongoose = require('mongoose');

const userLocationSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
  },
  province: {
    type: String,
    required: true,
  },
  city: {
    type: String,
    required: true,
  },
});

const UserLocation = mongoose.model('UserLocation', userLocationSchema);

module.exports = UserLocation; 