# Stage 1: Base image with common dependencies
FROM pareskomon/dev:base-base AS base

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

RUN wget -O models/insightface/models/buffalo_l/1k3d68.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/buffalo_l/1k3d68.onnx && \
    wget -O models/insightface/models/buffalo_l/2d106det.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/buffalo_l/2d106det.onnx && \
    wget -O models/insightface/models/buffalo_l/det_10g.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/buffalo_l/det_10g.onnx && \
    wget -O models/insightface/models/buffalo_l/genderage.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/buffalo_l/genderage.onnx && \
    wget -O models/insightface/models/buffalo_l/w600k_r50.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/buffalo_l/w600k_r50.onnx

RUN wget -O models/facerestore_models/codeformer-v0.1.0.pth https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/facerestore_models/codeformer-v0.1.0.pth && \
    wget -O models/facerestore_models/GFPGANv1.3.pth https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/facerestore_models/GFPGANv1.3.pth && \
    wget -O models/facerestore_models/GFPGANv1.4.pth https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/facerestore_models/GFPGANv1.4.pth && \
    wget -O models/facerestore_models/GPEN-BFR-512.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/facerestore_models/GPEN-BFR-512.onnx && \
    wget -O models/facerestore_models/GPEN-BFR-1024.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/facerestore_models/GPEN-BFR-1024.onnx && \
    wget -O models/facerestore_models/GPEN-BFR-2048.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/facerestore_models/GPEN-BFR-2048.onnx && \
    wget -O models/facedetection/detection_Resnet50_Final.pth https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/facedetection/detection_Resnet50_Final.pth && \
    wget -O models/facedetection/parsing_parsenet.pth https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/facedetection/parsing_parsenet.pth

RUN wget -O models/RMBG/RMBG-2.0/birefnet.py https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/RMBG/RMBG-2.0/birefnet.py && \
    wget -O models/RMBG/RMBG-2.0/BiRefNet_config.py https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/RMBG/RMBG-2.0/BiRefNet_config.py && \
    wget -O models/RMBG/RMBG-2.0/config.json https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/RMBG/RMBG-2.0/config.json && \
    wget -O models/RMBG/RMBG-2.0/model.safetensors https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/RMBG/RMBG-2.0/model.safetensors

RUN wget -O models/insightface/inswapper_128.onnx https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/insightface/inswapper_128.onnx

# Stage 3: Final image
FROM base AS final

COPY --from=downloader /comfyui/models /comfyui/models

# Start container
CMD ["/start.sh"]