### FFmpeg:
Windows:
```
winget install "FFmpeg (Essentials Build)"
```

### ✅ Install:
https://github.com/yt-dlp/yt-dlp?tab=readme-ov-file#installation

### ✅ Commands:

#### 1. **MP3 (Highest Audio Quality):**

```bash
yt-dlp -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0 -o "%(title)s.%(ext)s" "<video_url>"
```

#### 2. **MP4 (1080p Video):**

```bash
yt-dlp -f "bestvideo[ext=mp4][height=1080]+bestaudio[ext=m4a]/best[ext=mp4][height=1080]" -o "%(title)s.%(ext)s" "<video_url>"
```

#### 3. **MP4 (4K Video):**

```bash
yt-dlp -f "bestvideo[ext=mp4][height=2160]+bestaudio[ext=m4a]/best[ext=mp4][height=2160]" -o "%(title)s.%(ext)s" "<video_url>"
```

These will all save files with the video's title as the filename (e.g., `Cool YouTube Video.mp3` or `.mp4`).

