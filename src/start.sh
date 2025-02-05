#!/usr/bin/env bash

echo "Symlinking files from Network Volume"

SOURCE_DIR="/runpod-volume/models"
TARGET_LINK="/comfyui/models"
rm -rf /comfyui/models

# Create the symbolic link
ln -s "$SOURCE_DIR" "$TARGET_LINK"

# Verify the symlink was created
if [ -L "$TARGET_LINK" ]; then
    echo "Symlink created: $TARGET_LINK -> $SOURCE_DIR"
else
    echo "Failed to create symlink."
fi

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    echo "runpod-worker-comfy: Starting ComfyUI"
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata --listen &

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    echo "runpod-worker-comfy: Starting ComfyUI"
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata &

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py
fi