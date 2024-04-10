# FFmpeg tricks

### blur the bottom 80% of the frame + trim
```bash
ffmpeg -i input.mp4 -ss 00:00:27 -to 00:01:25 -filter_complex "[0:v]split=2[main][blur];[blur]crop=iw:ih*0.8,gblur=sigma=20[blurred];[main][blurred]overlay=0:H-h,scale=1920:1080" -c:v libx264 -preset slow -crf 23 -c:a copy output.mp4
```
