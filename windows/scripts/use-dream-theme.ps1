[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$ProfilePath,
  [switch]$Reapply
)

$ErrorActionPreference = 'Stop'
$themesRoot = Join-Path $PSScriptRoot '..\themes'
$activePath = Join-Path $themesRoot 'active.json'
$resolvedProfilePath = [System.IO.Path]::GetFullPath($ProfilePath)
if (-not (Test-Path -LiteralPath $resolvedProfilePath -PathType Leaf)) {
  throw "Theme profile was not found: $resolvedProfilePath"
}

try {
  $profile = Get-Content -LiteralPath $resolvedProfilePath -Raw -Encoding utf8 | ConvertFrom-Json -ErrorAction Stop
} catch {
  throw "Theme profile is not valid JSON: $resolvedProfilePath"
}
if ([string]::IsNullOrWhiteSpace($profile.artPath) -or -not [System.IO.Path]::IsPathRooted([string]$profile.artPath)) {
  throw 'Theme profile must contain an absolute artPath.'
}
if (-not (Test-Path -LiteralPath $profile.artPath -PathType Leaf)) {
  throw "Theme artwork was not found: $($profile.artPath)"
}

$temporaryPath = "$activePath.$([guid]::NewGuid().ToString('N')).tmp"
Copy-Item -LiteralPath $resolvedProfilePath -Destination $temporaryPath -Force
Move-Item -LiteralPath $temporaryPath -Destination $activePath -Force
Write-Host "Active Dream Skin theme: $($profile.name)"

if ($Reapply) {
  & (Join-Path $PSScriptRoot 'start-dream-skin.ps1')
}
