#!/bin/bash
# This script loads Docker images from a pre-saved tar file (services.img) into the local Docker daemon.
# This is used on the deployment machine after running downloadImages.sh on a machine with network access.
# On Linux/Mac, make it executable before use:chmod +x loadImages.sh

# Step 1: Check Docker daemon is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker daemon is not running. Please start Docker and try again."
    exit 1
fi

# Step 2: Check services.img exists
if [ ! -f "services.img" ]; then
    echo "ERROR: services.img not found in current directory. Run downloadImages.sh first."
    exit 1
fi

# Step 3: Load images
echo "--- Loading images from services.img ---"
if docker load -i services.img; then
    echo "SUCCESS: Images loaded."
else
    echo "ERROR: docker load failed."
    exit 1
fi
