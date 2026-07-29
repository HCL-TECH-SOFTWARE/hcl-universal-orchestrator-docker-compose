# This script loads Docker images from a pre-saved tar file (services.img) into the local Docker daemon.
# This is used on the deployment machine after running downloadImages.ps1 on a machine with network access.

# Step 1: Check Docker daemon is running
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker daemon is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Step 2: Check services.img exists
if (-not (Test-Path "services.img")) {
    Write-Host "ERROR: services.img not found in current directory. Run downloadImages.ps1 first." -ForegroundColor Red
    exit 1
}

# Step 3: Load images
Write-Host "--- Loading images from services.img ---" -ForegroundColor Yellow
docker load -i services.img
if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Images loaded." -ForegroundColor Green
} else {
    Write-Host "ERROR: docker load failed." -ForegroundColor Red
}

