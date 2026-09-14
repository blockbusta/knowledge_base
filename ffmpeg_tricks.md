# FFmpeg tricks

### blur the bottom 70% of the frame + trim
```bash
ffmpeg -i input.mp4 -ss 00:00:27 -to 00:01:25 -filter_complex "[0:v]split=2[main][blur];[blur]crop=iw:ih*0.7,gblur=sigma=20[blurred];[main][blurred]overlay=0:H-h,scale=1920:1080" -c:v libx264 -preset slow -crf 23 -c:a copy output.mp4
```

### burn subtitles to video
```bash
ffmpeg -i input.mp4 -vf "subtitles=input.srt:force_style='FontName=Arial,FontSize=18,PrimaryColour=&HFFFFFF&,OutlineColour=&H000000&,Outline=1'" -c:v libx264 -crf 23 -preset medium -c:a copy output_styled.mp4
```

### trim audio file
```bash
ffmpeg -ss 00:00:10 -to 00:00:45 -i input.wav -c copy output.wav
```

### create reel video waveform
```bash
ffmpeg -y -loop 1 -framerate 30 -i reel_template.jpeg -i reel_sound.wav -filter_complex "
[1:a]lowpass=f=220,showwaves=s=3072x2300:mode=cline:colors=0x00d4ff:rate=30:scale=sqrt[wave_hi];
[wave_hi]scale=1536:1150:flags=lanczos,format=rgba,colorkey=0x000000:0.15:0.08,gblur=sigma=3[wave_ck];
[wave_ck]split=2[wsharp][wblur_src];
[wblur_src]gblur=sigma=20[wglow];
[0:v]scale=1536:2752[bg];
[bg][wglow]overlay=x=0:y=1550[bg_glow];
[bg_glow][wsharp]overlay=x=0:y=1550[outv]
" -map "[outv]" -map 1:a -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest reel_waveform_output.mp4
```
