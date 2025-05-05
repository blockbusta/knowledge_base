# FFmpeg tricks

### blur the bottom 70% of the frame + trim
```bash
ffmpeg -i input.mp4 -ss 00:00:27 -to 00:01:25 -filter_complex "[0:v]split=2[main][blur];[blur]crop=iw:ih*0.7,gblur=sigma=20[blurred];[main][blurred]overlay=0:H-h,scale=1920:1080" -c:v libx264 -preset slow -crf 23 -c:a copy output.mp4
```

### burn subtitles to video
```bash
ffmpeg -i input.mp4 -vf "subtitles=input.srt:force_style='FontName=Arial,FontSize=18,PrimaryColour=&HFFFFFF&,OutlineColour=&H000000&,Outline=1'" -c:v libx264 -crf 23 -preset medium -c:a copy output_styled.mp4
```
