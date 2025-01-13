# Stage 1: Base image with common dependencies
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 AS base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 
# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    libgl1 \
    && ln -sf /usr/bin/python3.10 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install comfy-cli
RUN pip install comfy-cli

# Install ComfyUI
RUN /usr/bin/yes | comfy --workspace /comfyui install --cuda-version 11.8 --nvidia --version 0.2.7

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install runpod
RUN pip install runpod requests

# Support for the network volume
ADD src/extra_model_paths.yaml ./

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

# Create necessary directories
RUN mkdir -p models/checkpoints models/vae models/controlnet models/instantid models/insightface/models/antelopev2 models/insightface/models/buffalo_l models/facerestore_models models/facedetection models/rembg

# Download aditional models

RUN wget -O models/instantid/intantID_ip-adapter.bin https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/instantid/intantID_ip-adapter.bin && \
    wget -O models/controlnet/Union-sdxl_model.safetensors https://cybersimsai.s3.us-east-1.amazonaws.com/workspace/models/controlnet/Union-sdxl_model.safetensors && \
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

RUN wget -O models/rembg/u2net_human_seg.onnx https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2net_human_seg.onnx

RUN mkdir -p input && \
    wget -O input/MaskPersonelShape.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/MaskPersonelShape.png && \
    wget -O input/MaskBackCircle.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/MaskBackCircle.png && \
    wget -O input/MaskFrontHalfCirc.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/MaskFrontHalfCirc.png && \
    wget -O input/MaskPersonel.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/MaskPersonel.png && \
    wget -O input/MaskRoboto.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/MaskRoboto.png && \
    wget -O input/VMaskBackCircle.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/VMaskBackCircle.png && \
    wget -O input/VMaskFrontHalfCirc.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/VMaskFrontHalfCirc.png && \
    wget -O input/VMaskPersonel.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/VMaskPersonel.png && \
    wget -O input/VMaskRoboto.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/VMaskRoboto.png && \
    wget -O input/bg_horizontal.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/bg_horizontal.png && \
    wget -O input/bg_vertical.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/bg_vertical.png && \
    wget -O input/moldura-01.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/moldura-01.png && \
    wget -O input/moldura-02.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/moldura-02.png && \
    wget -O input/ROBBBB+CHAVE_3.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/ROBBBB%2BCHAVE_3.png && \
    wget -O input/Reference_two.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/Reference_two.png

# Stage 3: Final image
FROM base AS final

# Copy models from stage 2 to the final image
COPY --from=downloader /comfyui/models /comfyui/models
COPY --from=downloader /comfyui/input /comfyui/input

# Start container
CMD ["/start.sh"]