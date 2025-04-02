# Specify your input file
$inputFile = "ner_swing.mp4"
$trimStart = "00:00:08"
$trimEnd = "00:00:35"

# Get file parts
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
$extension = [System.IO.Path]::GetExtension($inputFile) # Includes the dot

# Construct the output filename
$centerFile = "${baseName}_center${extension}"
$backgroundFile = "${baseName}_background${extension}"
$outputFile = "${baseName}_output${extension}"

Write-Host "Input file: $inputFile"
Write-Host "Center file: $centerFile"
Write-Host "Background file: $backgroundFile"
Write-Host "Output file: $outputFile"

ffmpeg -i $inputFile -ss $trimStart -to $trimEnd -vf "crop=iw:ih/3:0:0" -c:a copy $centerFile
ffmpeg -i $centerFile -vf "boxblur=10:5,scale=1920:1080,setsar=1" -an $backgroundFile
ffmpeg -i $backgroundFile -i $centerFile -filter_complex "[0:v][1:v]overlay=(W-w)/2:(H-h)/2[outv]" -map "[outv]" -map 1:a? -c:a copy $outputFile

Remove-Item -Path $centerFile
Remove-Item -Path $backgroundFile

Write-Host "FFmpeg processing finished."

# to execute:
# powershell.exe -ExecutionPolicy Bypass -File .\converter.ps1