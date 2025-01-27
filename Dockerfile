# Stage 1: Base image with common dependencies
FROM pareskomon/dev:cannon AS base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 
# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Go back to the root
WORKDIR /

# Add scripts
ADD src/start.sh src/restore_snapshot.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh /restore_snapshot.sh

# Optionally copy the snapshot file
ADD *snapshot*.json /

# Restore the snapshot to install custom nodes
RUN /restore_snapshot.sh

# Start container
CMD ["/start.sh"]

# Stage 2: Download models
FROM base AS downloader

ARG HUGGINGFACE_ACCESS_TOKEN
ARG MODEL_TYPE

# Change working directory to ComfyUI
WORKDIR /comfyui

RUN mkdir -p models/checkpoints models/vae models/controlnet models/instantid models/insightface/models/antelopev2 models/insightface/models/buffalo_l models/facerestore_models models/facedetection models/RMBG/RMBG-2.0 models/insightface

RUN wget -O models/instantid/intantID_ip-adapter.bin https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/instantid/intantID_ip-adapter.bin && \
    wget -O models/insightface/models/antelopev2/1k3d68.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/antelopev2/1k3d68.onnx && \
    wget -O models/insightface/models/antelopev2/2d106det.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/antelopev2/2d106det.onnx && \
    wget -O models/insightface/models/antelopev2/genderage.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/antelopev2/genderage.onnx && \
    wget -O models/insightface/models/antelopev2/glintr100.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/antelopev2/glintr100.onnx && \
    wget -O models/insightface/models/antelopev2/scrfd_10g_bnkps.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/antelopev2/scrfd_10g_bnkps.onnx


# Stage 3: Final image
FROM base AS final

COPY --from=downloader /comfyui/models /comfyui/models

# Start container
CMD ["/start.sh"]