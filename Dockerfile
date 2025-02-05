# Stage 1: Base image with common dependencies
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

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
RUN /usr/bin/yes | comfy --workspace /comfyui install --cuda-version 11.8 --nvidia --version 0.3.13

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install runpod
RUN pip install runpod requests

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
FROM base as downloader

ARG HUGGINGFACE_ACCESS_TOKEN
ARG MODEL_TYPE

RUN mkdir -p input
RUN wget -O /comfyui/input/bg_horizontal.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/bg_horizontal.png && \
    wget -O /comfyui/input/bg_vertical.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/bg_vertical.png && \
    wget -O /comfyui/input/MaskBackCircle.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/MaskBackCircle.png && \
    wget -O /comfyui/input/MaskFrontHalfCirc.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/MaskFrontHalfCirc.png && \
    wget -O /comfyui/input/MaskPersonel.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/MaskPersonel.png && \
    wget -O /comfyui/input/MaskPersonelShape.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/MaskPersonelShape.png && \
    wget -O /comfyui/input/MaskRoboto.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/MaskRoboto.png && \
    wget -O /comfyui/input/moldura-01.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/moldura-01.png && \
    wget -O /comfyui/input/moldura-02.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/moldura-02.png && \
    wget -O /comfyui/input/PATCH1.jpg https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/PATCH1.jpg && \
    wget -O /comfyui/input/PATCH2.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/PATCH2.png && \
    wget -O /comfyui/input/PATCH3.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/PATCH3.png && \
    wget -O /comfyui/input/PATCH4.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/PATCH4.png && \
    wget -O /comfyui/input/PATCH5.jpg https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/PATCH5.jpg && \
    wget -O /comfyui/input/Reference_two.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/Reference_two.png && \
    wget -O /comfyui/input/ROBBBB+CHAVE_3.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/ROBBBB%2BCHAVE_3.png && \
    wget -O /comfyui/input/VMaskBackCircle.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/VMaskBackCircle.png && \
    wget -O /comfyui/input/VMaskFrontHalfCirc.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/VMaskFrontHalfCirc.png && \
    wget -O /comfyui/input/VMaskPersonel.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/VMaskPersonel.png && \
    wget -O /comfyui/input/VMaskRoboto.png https://cybersimsai.s3.us-east-1.amazonaws.com/MRV-BBB/Input+Masks/VMaskRoboto.png

# Change working directory to ComfyUI
WORKDIR /comfyui

# Stage 3: Final image
FROM base as final

# Copy models from stage 2 to the final image

COPY --from=downloader /comfyui/input /comfyui/input

# Delete the /comfyui/models folder for symlink and lighter dockerfile.
RUN rm -rf /comfyui/models

# Start container
CMD ["/start.sh"]