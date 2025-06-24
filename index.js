const express = require('express');
const cors = require('cors');
const { execFile } = require('child_process');
const { promisify } = require('util');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const execFileAsync = promisify(execFile);
const app = express();

const config = {
  PORT: process.env.PORT || 8080,
  DOWNLOADS_DIR: path.resolve('./downloads'),
  DOWNLOAD_TIMEOUT: 1800000, // 30 min
  COOKIES_PATH: path.resolve('./final_cookies.txt'),
  MAX_CONCURRENT_DOWNLOADS: 3,
  ACTIVE_DOWNLOADS: new Map()
};

app.use(cors());
app.use(express.json());

// Create downloads directory
if (!fs.existsSync(config.DOWNLOADS_DIR)) {
  fs.mkdirSync(config.DOWNLOADS_DIR, { recursive: true });
}

function sanitizeFilename(name) {
  return name.replace(/[^a-z0-9\-._]/gi, '_').substring(0, 150);
}

async function downloadVideo(url, outputPath) {
  const args = [
    '--no-warnings',
    '--force-ipv4',
    '--socket-timeout', '30',
    '--retries', '5',
    '--merge-output-format', 'mp4',
    '-o', outputPath,
    '--no-mtime',
    '--no-cache-dir',
    '--no-part',
    '--format', 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'
  ];

  if (fs.existsSync(config.COOKIES_PATH)) {
    args.push('--cookies', config.COOKIES_PATH);
  }
  args.push(url);

  await execFileAsync('yt-dlp', args, {
    timeout: config.DOWNLOAD_TIMEOUT,
    maxBuffer: 1024 * 1024 * 20 
  });

  if (!fs.existsSync(outputPath)) {
    throw new Error('Downloaded file not found');
  }
  return outputPath;
}

app.post('/download', async (req, res) => {
  if (config.ACTIVE_DOWNLOADS.size >= config.MAX_CONCURRENT_DOWNLOADS) {
    return res.status(429).json({ error: 'Server busy' });
  }

  const { url, customFilename } = req.body;
  if (!url) return res.status(400).json({ error: 'URL is required' });

  try { new URL(url); } catch { return res.status(400).json({ error: 'Invalid URL' }); }

  const fileId = Date.now();
  const filename = customFilename
    ? `${fileId}_${sanitizeFilename(customFilename)}.mp4`
    : `${fileId}.mp4`;
  const filePath = path.join(config.DOWNLOADS_DIR, filename);

  config.ACTIVE_DOWNLOADS.set(fileId, filePath);

  try {
    await downloadVideo(url, filePath);

    const fileBuffer = fs.readFileSync(filePath);
    res.setHeader('Content-Type', 'video/mp4');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(fileBuffer);

    fs.unlink(filePath, () => {});
    config.ACTIVE_DOWNLOADS.delete(fileId);
  } catch (error) {
    config.ACTIVE_DOWNLOADS.delete(fileId);
    console.error('Download failed:', error);
    res.status(500).json({ error: 'Download failed', details: error.message });
  }
});

app.get('/status', (req, res) => {
  res.json({
    status: 'OK',
    activeDownloads: config.ACTIVE_DOWNLOADS.size,
    downloadsDirectory: config.DOWNLOADS_DIR,
    cookiesAvailable: fs.existsSync(config.COOKIES_PATH)
  });
});

app.listen(config.PORT, () => {
  console.log(`🚀 Server running on port ${config.PORT}`);
});
