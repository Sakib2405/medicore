Param(
  [string]$DeviceId,
  [switch]$Uninstall,
  [string]$AppId = 'com.example.medicore',
  [switch]$NoClean
)

$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host "[info] $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[warn] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[err ] $msg" -ForegroundColor Red }

# Resolve repo root (script is in tools/)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repoRoot

try {
  # Ensure Flutter is accessible
  try {
    Write-Info 'Checking Flutter...'
    flutter --version | Out-Null
  } catch {
    Write-Err 'Flutter not found on PATH. Install Flutter or add it to PATH.'
    exit 1
  }

  # Find Android device id if not provided
  if (-not $DeviceId) {
    Write-Info 'Detecting Android devices...'
    $json = ''
    try { $json = flutter devices --machine 2>$null } catch {}
    if ($json) {
      $devices = $json | ConvertFrom-Json
      $android = @($devices | Where-Object { $_.platform -eq 'android' -or $_.platformType -eq 'android' -or ($_.targetPlatform -like 'android*') })
      if ($android.Count -gt 0) {
        $DeviceId = $android[0].id
        Write-Info "Using device: $($android[0].name) ($DeviceId)"
      }
    }
    if (-not $DeviceId) {
      # Fallback to parsing text output
      $txt = flutter devices
      $line = ($txt -split "`n") | Where-Object { $_ -match 'android.*\sdevice$' } | Select-Object -First 1
      if ($line) {
        # format: <name> (mobile) • <id> • android-... • device
        if ($line -match '•\s([^\s]+)\s•\sandroid') { $DeviceId = $Matches[1] }
      }
    }
    if (-not $DeviceId) {
      Write-Err 'No Android device found. Connect a device or start an emulator.'
      flutter devices
      exit 1
    }
  }

  # Optional: uninstall previous app to avoid stale installs
  if ($Uninstall) {
    Write-Info "Attempting uninstall of $AppId on $DeviceId"
    function Get-AdbPath {
      try { (Get-Command adb -ErrorAction Stop).Path } catch {
        $lp = Join-Path $repoRoot 'android/local.properties'
        if (Test-Path $lp) {
          $sdkLine = (Get-Content $lp | Where-Object { $_ -like 'sdk.dir=*' } | Select-Object -First 1)
          if ($sdkLine) {
            $sdkDir = ($sdkLine -replace '^sdk\.dir=', '') -replace '\\\\','\'
            $candidate = Join-Path $sdkDir 'platform-tools/adb.exe'
            if (Test-Path $candidate) { return $candidate }
          }
        }
        return $null
      }
    }
    $adb = Get-AdbPath
    if ($adb) {
      try {
        & $adb -s $DeviceId uninstall $AppId | Out-Host
      } catch {
        Write-Warn "Uninstall failed or app not installed: $($_.Exception.Message)"
      }
    } else {
      Write-Warn 'ADB not found. Skipping uninstall.'
    }
  }

  if (-not $NoClean) {
    Write-Info 'Cleaning build and tool cache...'
    flutter clean
    # Extra safety cleanup (ignore errors if absent)
    Remove-Item -Recurse -Force .\.dart_tool, .\build -ErrorAction SilentlyContinue
  }

  Write-Info 'Resolving dependencies (flutter pub get)...'
  flutter pub get

  Write-Info "Running app on $DeviceId in debug..."
  flutter run -d $DeviceId --debug

  Write-Info 'Tip: In the Flutter console, press Shift+R for a full restart.'
}
finally {
  Pop-Location
}
