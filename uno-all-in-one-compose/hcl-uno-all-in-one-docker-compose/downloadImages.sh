#!/bin/bash
# This script exports all Docker images needed by the UnO all-in-one deployment into a single portable tar file (services.img).
# This avoids needing registry credentials or network access on the deployment machine.
# On Linux/Mac, make it executable before use:chmod +x loadImages.sh

set -e

# Step 1: Get resolved config and extract image names
echo "--- Running docker compose config ---"
config_output=$(docker compose --env-file main.env --profile "*" -f docker-compose.yml -f uno-compose-prerequisites.yml config 2>&1)
if [ $? -ne 0 ]; then
    echo "ERROR: docker compose config failed:"
    echo "$config_output"
    exit 1
fi

# Step 2: Parse image lines
images=()
while IFS= read -r line; do
    trimmed=$(echo "$line" | xargs)
    if echo "$trimmed" | grep -qE '^\s*image:\s+'; then
        img=$(echo "$trimmed" | sed 's/^\s*image:\s*//')
        echo "Found image: $img"
        images+=("$img")
    fi
done <<< "$config_output"

# Step 3: Deduplicate images
mapfile -t images < <(printf '%s\n' "${images[@]}" | sort -u)
echo ""
echo "--- Final images list (${#images[@]} unique images) ---"
for img in "${images[@]}"; do
    echo "  $img"
done

# Step 4: Check Docker daemon is running
echo ""
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker daemon is not running. Please start Docker and try again."
    exit 1
fi

# Step 5: Pull images locally
echo "--- Pulling images ---"
failed_pulls=()
for img in "${images[@]}"; do
    echo "Pulling: $img"
    if docker pull "$img" 2>&1; then
        echo "  OK"
    else
        echo "  FAILED to pull $img"
        failed_pulls+=("$img")
    fi
done

if [ ${#failed_pulls[@]} -gt 0 ]; then
    echo ""
    echo "WARNING: Failed to pull ${#failed_pulls[@]} image(s):"
    for img in "${failed_pulls[@]}"; do
        echo "  $img"
    done
    echo "These images will be skipped from the save."
    # Remove failed images from the list
    surviving=()
    for img in "${images[@]}"; do
        skip=false
        for failed in "${failed_pulls[@]}"; do
            if [ "$img" = "$failed" ]; then
                skip=true
                break
            fi
        done
        if [ "$skip" = false ]; then
            surviving+=("$img")
        fi
    done
    images=("${surviving[@]}")
fi

# Step 6: Save all images to tar
if [ ${#images[@]} -gt 0 ]; then
    echo ""
    echo "--- Saving ${#images[@]} images to services.img ---"
    if docker save -o services.img "${images[@]}"; then
        echo "SUCCESS: Saved ${#images[@]} images to services.img"
    else
        echo "ERROR: docker save failed"
        exit 1
    fi
else
    echo "WARNING: No images found, nothing to save."
fi
