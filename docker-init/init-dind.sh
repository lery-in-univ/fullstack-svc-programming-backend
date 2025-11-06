#!/bin/sh
set -e

echo "Starting custom DinD initialization..."

# Start dockerd in the background
dockerd --host=tcp://0.0.0.0:2375 --host=unix:///var/run/docker.sock &
DOCKERD_PID=$!

echo "Waiting for Docker daemon to be ready..."

# Wait for dockerd to be ready (more reliable than sleep)
timeout=60
counter=0
until docker info >/dev/null 2>&1; do
    counter=$((counter + 1))
    if [ $counter -gt $timeout ]; then
        echo "ERROR: Docker daemon failed to start within ${timeout} seconds"
        exit 1
    fi
    echo "Waiting for Docker daemon... (${counter}s/${timeout}s)"
    sleep 1
done

echo "Docker daemon is ready!"

# Pre-pull required images
echo "Pre-pulling busybox image..."
docker pull busybox:latest

echo "Image pre-pull complete!"
docker images

# Keep the script running and forward signals to dockerd
trap "kill $DOCKERD_PID" TERM INT
wait $DOCKERD_PID
