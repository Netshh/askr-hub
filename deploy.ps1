# deploy.ps1
# Automates Prometheus Obfuscation and GitHub Deployment

$PROMETHEUS_PATH = "D:\Robloxx\Chts\Netsh Dev\Obfuscator\Prometheus-master"
$SOURCE_FILE = "askr_hub_vd_wind.lua"
$OUTPUT_FILE = "source.lua"
$PRESET = "Weak" # Options: Minify, Weak, Medium, Strong
$COMMIT_MESSAGE = "Update Hub: " + (Get-Date).ToString("yyyy-MM-dd HH:mm")

Write-Host "--- ASKR HUB DEPLOYER (Prometheus) ---" -ForegroundColor Cyan

# 1. Check Prerequisites
if (-not (Get-Command lua -ErrorAction SilentlyContinue)) {
    Write-Error "Lua is not installed or not in your PATH. Please install Lua 5.1."
    exit 1
}

# 2. Obfuscate with Prometheus
Write-Host "Obfuscating '$SOURCE_FILE' using Prometheus ($PRESET preset)..." -ForegroundColor Yellow
$currentDir = Get-Location
Set-Location $PROMETHEUS_PATH

# Run Prometheus
$fullSourcePath = "$currentDir\$SOURCE_FILE"
$fullOutputPath = "$currentDir\$OUTPUT_FILE"
lua cli.lua --preset $PRESET "$fullSourcePath" --out "$fullOutputPath"

Set-Location $currentDir

if (-not (Test-Path $OUTPUT_FILE)) {
    Write-Host "Obfuscation failed! Output file not created." -ForegroundColor Red
    exit 1
}
Write-Host "Obfuscation complete: $OUTPUT_FILE" -ForegroundColor Green

# 3. Git Deployment
Write-Host "Committing to GitHub..." -ForegroundColor Yellow

# Explicitly ensure source code is removed from Git tracking
if (Test-Path $SOURCE_FILE) {
    git rm --cached $SOURCE_FILE -f --ignore-unmatch
}

# Track only release files
git add .gitignore
git add $OUTPUT_FILE

if (-not (Test-Path "loader.lua")) {
    Write-Warning "loader.lua not found! It will be removed from the repo if you continue."
} else {
    git add loader.lua
}
git add askrlogo.png
git commit -m $COMMIT_MESSAGE

# Force push to overwrite the remote and REMOVE the source file from GitHub
git push origin main --force

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment Successful! Source code has been removed from GitHub." -ForegroundColor Green
    Write-Host "Public Files: source.lua, loader.lua, askrlogo.png" -ForegroundColor Cyan
} else {
    Write-Host "Git push failed. Check your connection or GitHub permissions." -ForegroundColor Red
}
