# This script exports all Docker images needed by the UnO all-in-one deployment into a single portable tar file (services.img)
#This avoids needing registry credentials or network access on the deployment machine.

# Step 1: Get resolved config and extract image names
Write-Host "--- Running docker compose config ---"
$configOutput = docker compose --env-file main.env --profile "*" -f docker-compose.yml -f uno-compose-prerequisites.yml config 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: docker compose config failed:" -ForegroundColor Red
    Write-Host $configOutput
    exit 1
}

# Step 2: Parse image lines
$images = @()
foreach ($line in ($configOutput -split "`n")) {
    $trimmed = $line.Trim()
    if ($trimmed -match '^\s*image:\s+(.+)$') {
        $img = $Matches[1].Trim()
        Write-Host "Found image: $img" -ForegroundColor Cyan
        $images += $img
    }
}

# Step 3: Deduplicate images
$images = $images | Select-Object -Unique
Write-Host ""
Write-Host "--- Final images list ($($images.Count) unique images) ---" -ForegroundColor Green
$images | ForEach-Object { Write-Host "  $_" }

# Step 4: Check Docker daemon is running
Write-Host ""
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker daemon is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Step 5: Pull images locally
Write-Host "--- Pulling images ---" -ForegroundColor Yellow
$failedPulls = @()
foreach ($img in $images) {
    Write-Host "Pulling: $img" -ForegroundColor Cyan
    docker pull $img 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FAILED to pull $img" -ForegroundColor Red
        $failedPulls += $img
    } else {
        Write-Host "  OK" -ForegroundColor Green
    }
}

if ($failedPulls.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Failed to pull $($failedPulls.Count) image(s):" -ForegroundColor Yellow
    $failedPulls | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host "These images will be skipped from the save." -ForegroundColor Yellow
    $images = $images | Where-Object { $_ -notin $failedPulls }
}

# Step 6: Save all images to tar
if ($images.Count -gt 0) {
    Write-Host ""
    Write-Host "--- Saving $($images.Count) images to services.img ---" -ForegroundColor Yellow
    docker save -o services.img @images
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Saved $($images.Count) images to services.img" -ForegroundColor Green
    } else {
        Write-Host "ERROR: docker save failed" -ForegroundColor Red
    }
} else {
    Write-Host "WARNING: No images found nothing to save" -ForegroundColor Yellow
}
