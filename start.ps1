## Oraiopoli - Start All Services
#
# Usage:  .\start.ps1          (starts everything, streams logs)
#         .\start.ps1 -Stop    (stops everything)
#

param([switch]$Stop)

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

$BackendDir = Join-Path $Root "backend"
$AdminDir   = Join-Path $Root "admin"
$MobileDir  = Join-Path $Root "mobile"
$LogDir     = Join-Path $Root ".logs"

# -- Find Java --
$JavaExe = "java"
$jdksDir = Join-Path $env:USERPROFILE ".jdks"
if (Test-Path $jdksDir) {
    $jdk = Get-ChildItem $jdksDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($jdk) {
        $found = Join-Path $jdk.FullName "bin\java.exe"
        if (Test-Path $found) { $JavaExe = $found }
    }
}

# -- Stop mode --
if ($Stop) {
    Write-Host ""
    Write-Host "  Stopping all services..." -ForegroundColor Yellow
    Write-Host ""

    Get-Process -Name "java" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "  [x] Spring Boot stopped" -ForegroundColor Red

    Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "  [x] Admin dev server stopped" -ForegroundColor Red

    Get-Process -Name "dart" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "  [x] Flutter stopped" -ForegroundColor Red

    Set-Location $Root
    docker compose down 2>$null
    Write-Host "  [x] Docker containers stopped" -ForegroundColor Red

    Write-Host ""
    Write-Host "  All services stopped." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# -- Banner --
Write-Host ""
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host "         ORAIOPOLI  -  Dev Stack          " -ForegroundColor Cyan
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ""

# -- Prepare log directory --
New-Item -ItemType Directory -Force $LogDir | Out-Null
$backendLog = Join-Path $LogDir "backend.log"
$adminLog   = Join-Path $LogDir "admin.log"
$flutterLog = Join-Path $LogDir "flutter.log"
"" | Set-Content $backendLog
"" | Set-Content $adminLog
"" | Set-Content $flutterLog

# -- 1. Docker Compose --
Write-Host "  [1/4] Starting PostgreSQL..." -ForegroundColor Green
Set-Location $Root
docker compose up -d 2>$null
Write-Host "        PostgreSQL on port 5432" -ForegroundColor DarkGray

Write-Host "        Waiting for PostgreSQL..." -ForegroundColor DarkGray
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    docker exec oraiopoli-postgres pg_isready -U postgres 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    Start-Sleep -Seconds 1
}
if ($ready) {
    Write-Host "        PostgreSQL is ready!" -ForegroundColor DarkGray
} else {
    Write-Host "        WARNING: PostgreSQL may not be ready yet" -ForegroundColor Yellow
}

# -- 2. Spring Boot Backend --
Write-Host "  [2/4] Starting Spring Boot backend..." -ForegroundColor Green
Write-Host "        Using Java: $JavaExe" -ForegroundColor DarkGray
$jar = Get-ChildItem -Path "$BackendDir\target\*.jar" -Exclude "*.original" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($jar) {
    $jarPath = $jar.FullName
    Start-Process cmd.exe -ArgumentList "/c cd /d `"$BackendDir`" & `"$JavaExe`" -jar `"$jarPath`" > `"$backendLog`" 2>&1" `
        -WindowStyle Hidden
    Write-Host "        Backend starting on http://localhost:8080" -ForegroundColor DarkGray
} elseif (Test-Path "$BackendDir\mvnw.cmd") {
    Start-Process cmd.exe -ArgumentList "/c cd /d `"$BackendDir`" & mvnw.cmd spring-boot:run > `"$backendLog`" 2>&1" `
        -WindowStyle Hidden
    Write-Host "        Backend starting on http://localhost:8080" -ForegroundColor DarkGray
} else {
    Write-Host "        ERROR: No JAR or mvnw found. Start backend from IntelliJ." -ForegroundColor Red
}

# -- 3. Admin Vite dev server --
Write-Host "  [3/4] Starting Admin panel..." -ForegroundColor Green
Start-Process cmd.exe -ArgumentList "/c cd /d `"$AdminDir`" & npm run dev > `"$adminLog`" 2>&1" `
    -WindowStyle Hidden
Write-Host "        Admin panel on http://localhost:5173" -ForegroundColor DarkGray

# -- 4. Flutter Chrome --
Write-Host "  [4/5] Starting Flutter mobile app..." -ForegroundColor Green
Start-Process cmd.exe -ArgumentList "/c cd /d `"$MobileDir`" & flutter run -d chrome > `"$flutterLog`" 2>&1" `
    -WindowStyle Hidden
Write-Host "        Flutter dev on http://localhost (random port)" -ForegroundColor DarkGray

# -- 5. Web app for LAN access --
Write-Host "  [5/5] Serving web app for LAN access..." -ForegroundColor Green
Start-Process cmd.exe -ArgumentList "/c cd /d `"$MobileDir`" & flutter build web --release >nul 2>&1 & python -m http.server 3000 --bind 0.0.0.0 --directory `"$MobileDir\build\web`"" `
    -WindowStyle Hidden
Write-Host "        LAN web app on http://192.168.2.3:3000" -ForegroundColor DarkGray

# -- Summary --
Write-Host ""
Write-Host "  ----------------------------------------" -ForegroundColor Cyan
Write-Host "  All services starting!" -ForegroundColor Cyan
Write-Host ""
Write-Host "    PostgreSQL   http://localhost:5432" -ForegroundColor White
Write-Host "    Backend API  http://localhost:8080" -ForegroundColor White
Write-Host "    Admin Panel  http://localhost:5173" -ForegroundColor White
Write-Host "    Flutter Dev  http://localhost (check log for port)" -ForegroundColor White
Write-Host "    LAN Web App  http://192.168.2.3:3000" -ForegroundColor White
Write-Host "    Swagger UI   http://localhost:8080/swagger-ui.html" -ForegroundColor White
Write-Host ""
Write-Host "    Stop all:    .\start.ps1 -Stop" -ForegroundColor Yellow
Write-Host "  ----------------------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Streaming logs... Press Ctrl+C to stop all." -ForegroundColor DarkGray
Write-Host ""

# -- Tail all logs in the current terminal --
$backendPos = 0
$adminPos   = 0
$flutterPos = 0

while ($true) {
    # Backend log
    $lines = @(Get-Content $backendLog -ErrorAction SilentlyContinue)
    if ($lines.Count -gt $backendPos) {
        for ($i = $backendPos; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim()) {
                Write-Host "  [API]     " -ForegroundColor Cyan -NoNewline
                Write-Host $lines[$i]
            }
        }
        $backendPos = $lines.Count
    }

    # Admin log
    $lines = @(Get-Content $adminLog -ErrorAction SilentlyContinue)
    if ($lines.Count -gt $adminPos) {
        for ($i = $adminPos; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim()) {
                Write-Host "  [ADMIN]   " -ForegroundColor Green -NoNewline
                Write-Host $lines[$i]
            }
        }
        $adminPos = $lines.Count
    }

    # Flutter log
    $lines = @(Get-Content $flutterLog -ErrorAction SilentlyContinue)
    if ($lines.Count -gt $flutterPos) {
        for ($i = $flutterPos; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim()) {
                Write-Host "  [FLUTTER] " -ForegroundColor Magenta -NoNewline
                Write-Host $lines[$i]
            }
        }
        $flutterPos = $lines.Count
    }

    Start-Sleep -Milliseconds 300
}
