FROM node:20-slim

# Install yt-dlp + dependencies
RUN apt-get update && apt-get install -y \
    curl ffmpeg python3 \
    && curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp \
    && chmod a+rx /usr/local/bin/yt-dlp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy config files first (least likely to change)
COPY config/final_cookies.txt /app/final_cookies.txt

# Install dependencies (cached unless package.json changes)
COPY package*.json ./
RUN npm install --production

# Copy remaining files
COPY . .

# Verify critical files exist
RUN test -f /app/final_cookies.txt && echo "✅ Cookies file present" || echo "❌ Missing cookies file"
RUN yt-dlp --version

CMD ["node", "index.js"]
