const fs = require('fs');
const path = require('path');

const uploadsDir = path.join(__dirname, '..', 'public', 'uploads');

console.log('Checking uploads directory:', uploadsDir);

if (fs.existsSync(uploadsDir)) {
  console.log('Uploads directory exists');
  
  fs.readdir(uploadsDir, (err, files) => {
    if (err) {
      console.error('Error reading directory:', err);
      return;
    }
    
    console.log('Files in uploads directory:');
    files.forEach(file => {
      const filePath = path.join(uploadsDir, file);
      const stats = fs.statSync(filePath);
      console.log({
        name: file,
        size: stats.size,
        created: stats.birthtime,
        permissions: stats.mode
      });
    });
  });
} else {
  console.log('Uploads directory does not exist');
} 