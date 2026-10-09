# ============================================================
#  Shrink the original photos in pkg/ into web-ready files in assets/
#
#  Usage (from the project root):
#     powershell -NoProfile -ExecutionPolicy Bypass -File tools\resize-photos.ps1
#     powershell -NoProfile -ExecutionPolicy Bypass -File tools\resize-photos.ps1 -MaxSide 1600 -Quality 88
#
#  For every image found in pkg/ (sorted by the number in its file name) it:
#     * applies the EXIF orientation, so nothing comes out sideways
#     * scales it down until the long side is at most -MaxSide px
#     * saves it as assets/kigu-<n>.jpg with JPEG quality -Quality
#  The originals in pkg/ are never modified.
# ============================================================

param(
  [int]$MaxSide = 1200,
  [int]$Quality = 82
)

Add-Type -AssemblyName System.Drawing

$siteRoot = Split-Path -Parent $PSScriptRoot
$src = Join-Path $siteRoot 'pkg'
$dst = Join-Path $siteRoot 'assets'

if (-not (Test-Path $src)) {
  Write-Host "Source folder not found: $src"
  exit 1
}
New-Item -ItemType Directory -Force -Path $dst | Out-Null

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
  Where-Object { $_.MimeType -eq 'image/jpeg' }
$encQuality = [System.Drawing.Imaging.Encoder]::Quality

# sort by the number inside the file name (1.JPG, 2.JPG, ... 10.JPG)
$files = Get-ChildItem -Path $src -File |
  Where-Object { $_.Extension -match '^\.(jpe?g|png)$' } |
  Sort-Object @{ Expression = {
      $m = [regex]::Match($_.BaseName, '\d+')
      if ($m.Success) { [int]$m.Value } else { [int]::MaxValue }
    } }, Name

if (-not $files) {
  Write-Host "No images (.jpg / .jpeg / .png) found in $src"
  exit 1
}

$n = 0
$totalOut = 0

foreach ($f in $files) {
  $n++
  $outFile = Join-Path $dst ('kigu-' + $n + '.jpg')

  $img = [System.Drawing.Image]::FromFile($f.FullName)

  $ori = 1
  try { $ori = [int]$img.GetPropertyItem(274).Value[0] } catch { $ori = 1 }
  switch ($ori) {
    2 { $img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
    3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
    4 { $img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipY) }
    5 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipXY) }
    6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
    7 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipXY) }
    8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
  }

  $scale = [Math]::Min(1.0, $MaxSide / [Math]::Max($img.Width, $img.Height))
  $nw = [int][Math]::Round($img.Width * $scale)
  $nh = [int][Math]::Round($img.Height * $scale)

  $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
  $bmp.SetResolution(72, 72)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.DrawImage($img, 0, 0, $nw, $nh)
  $g.Dispose()

  $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $ep.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new($encQuality, [long]$Quality)
  $bmp.Save($outFile, $jpegCodec, $ep)

  $ep.Dispose()
  $bmp.Dispose()
  $img.Dispose()

  $inKB = (Get-Item $f.FullName).Length / 1KB
  $outKB = (Get-Item $outFile).Length / 1KB
  $totalOut += $outKB

  Write-Host ('  kigu-{0}.jpg  {1}x{2}  {3,7:N0} KB  <-  {4,8:N0} KB  ({5})' -f `
      $n, $nw, $nh, $outKB, $inKB, $f.Name)
}

Write-Host ''
Write-Host ('Done: {0} image(s), {1:N0} KB total written to {2}' -f $n, $totalOut, $dst)
Write-Host 'Remember: index.html needs one matching <img src="assets/kigu-N.jpg"> per photo.'
