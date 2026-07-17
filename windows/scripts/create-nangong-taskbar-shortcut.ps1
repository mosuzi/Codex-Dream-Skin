[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$skillRoot = Split-Path -Parent $PSScriptRoot
$nangongWan = -join @([char]0x5357, [char]0x5BAB, [char]0x5A49)
$artPath = Join-Path 'F:\mosuzi\pics' ($nangongWan + '1.png')
$codex = (Get-AppxPackage OpenAI.Codex | Sort-Object Version -Descending | Select-Object -First 1)
if ($null -eq $codex) { throw 'The official OpenAI.Codex Store package is not installed.' }
$codexExe = Join-Path $codex.InstallLocation 'app\ChatGPT.exe'
if (-not (Test-Path -LiteralPath $codexExe)) { throw "Codex executable not found: $codexExe" }
if (-not (Test-Path -LiteralPath $artPath)) { throw "Theme image not found: $artPath" }

$stateRoot = Join-Path $env:LOCALAPPDATA 'CodexDreamSkin'
New-Item -ItemType Directory -Force -Path $stateRoot | Out-Null
$iconPath = Join-Path $stateRoot 'Codex-Nangong-Wan.ico'

$baseIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($codexExe)
$baseImage = $baseIcon.ToBitmap()
$art = [System.Drawing.Image]::FromFile($artPath)
$canvas = [System.Drawing.Bitmap]::new(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.DrawImage($baseImage, [System.Drawing.Rectangle]::new(0, 0, 256, 256))

$badge = [System.Drawing.Rectangle]::new(164, 164, 84, 84)
$graphics.FillEllipse([System.Drawing.Brushes]::White, [System.Drawing.Rectangle]::new(160, 160, 92, 92))
$graphics.FillEllipse([System.Drawing.Brushes]::Black, [System.Drawing.Rectangle]::new(162, 162, 88, 88))
$state = $graphics.Save()
$clip = [System.Drawing.Drawing2D.GraphicsPath]::new()
$clip.AddEllipse($badge)
$graphics.SetClip($clip)
$sourceSide = [Math]::Min($art.Width, $art.Height)
$sourceX = [Math]::Max(0, [Math]::Min($art.Width - $sourceSide, [int]($art.Width * .23)))
$sourceY = [Math]::Max(0, [int](($art.Height - $sourceSide) * .12))
$graphics.DrawImage($art, $badge, [System.Drawing.Rectangle]::new($sourceX, $sourceY, $sourceSide, $sourceSide), [System.Drawing.GraphicsUnit]::Pixel)
$graphics.Restore($state)
$graphics.DrawEllipse([System.Drawing.Pens]::White, $badge)

$memory = [System.IO.MemoryStream]::new()
$canvas.Save($memory, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBytes = $memory.ToArray()
$writer = [System.IO.BinaryWriter]::new([System.IO.File]::Open($iconPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write))
try {
  $writer.Write([UInt16]0)
  $writer.Write([UInt16]1)
  $writer.Write([UInt16]1)
  $writer.Write([byte]0)
  $writer.Write([byte]0)
  $writer.Write([byte]0)
  $writer.Write([byte]0)
  $writer.Write([UInt16]1)
  $writer.Write([UInt16]32)
  $writer.Write([UInt32]$pngBytes.Length)
  $writer.Write([UInt32]22)
  $writer.Write($pngBytes)
} finally {
  $writer.Dispose()
  $memory.Dispose()
  $clip.Dispose()
  $graphics.Dispose()
  $canvas.Dispose()
  $art.Dispose()
  $baseImage.Dispose()
  $baseIcon.Dispose()
}

$taskbarFolder = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
New-Item -ItemType Directory -Force -Path $taskbarFolder | Out-Null
$previousShortcut = Get-ChildItem -LiteralPath $taskbarFolder -Filter ('Codex*' + $nangongWan + '.lnk') -ErrorAction SilentlyContinue
if ($null -ne $previousShortcut) { Remove-Item -LiteralPath $previousShortcut.FullName -Force }
$shortcutPath = Join-Path $taskbarFolder ('Codex - ' + $nangongWan + '.lnk')
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = (Get-Command powershell.exe -ErrorAction Stop).Source
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $PSScriptRoot 'start-dream-skin.ps1')`" -PromptRestart"
$shortcut.WorkingDirectory = $skillRoot
$shortcut.IconLocation = "$iconPath,0"
$shortcut.Description = 'Launch Codex with the Nangong Wan moonlit theme'
$shortcut.Save()

Write-Output ([pscustomobject]@{ ShortcutPath = $shortcutPath; IconPath = $iconPath; CodexExecutable = $codexExe } | ConvertTo-Json -Compress)
