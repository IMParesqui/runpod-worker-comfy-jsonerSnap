This is a clean confyUI repository, barebones. Use it to create a custom Docker Image to be mounted in the RUNPODS.

In order to make your workflow work properly, here are some advided steps:

# 1)
Open the desired workflow in a clean CONFY_LAUNCHER in order to install only the necessary nodes and no more heavy and undesired trash.
After ensuring the workflow is running, go to the manager and export a snapshot. The snapshot contains all the nodes and inportant info you need to make the workflow work. Do not worry, you won't need to manually install all of them.

# 2)
Place the snapshot in the root of the repository (the same place as this readme (¬_¬)). There is a restore_snapshot.sh in the source folder that installs the requirements of your workflow.

# 3)
If you desire to include any models in the docker iamge you must add the command to the 'Dockerfile'
Before the stage 3 add the download of checkpoints:

e.g.
'# Download checkpoints
RUN wget -O models/checkpoints/sd_xl_turbo_1.0.safetensors https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/d_xl_turbo_1.0.safetensors?download=true

the -O means the outputfoler with the output filename. Afterwards come the link of the model.
Do this for all needed models. 
¡Beware! Some of the custom nodes already download some internal models use this mostly for the modes listen in the 'extra_model_paths.yaml'.

# 4)
The 'extra_model_paths.yaml' works fine, but as far as I know it only works for the nodes listed inside it. Trying to add folders such as 'custom_nodes' or 'sams: models/sams/' as to this date do not work... hopefuly it will work in the future.

# 5)
To use the Network drive in the pods just add it while creating the serverless endpoint.
Make sure that the Network drive has indeed the models inside itself with the same structure of the 'extra_model_paths.yaml'.

Here is an important point in the extra models file: there are the first two (important) lines as an example:

  base_path: /runpod-volume
  checkpoints: models/checkpoint/

  in order to use the network drive you do NOT NEED to alter these lines adding struff like:

    base_path: /runpod-volume/workspace/
  checkpoints: models/checkpoint/
or
    base_path: /workspace/
  checkpoints: models/checkpoint/
 or
    base_path: /runpod-volume
  checkpoints: workspace/models/checkpoint/

DO NOT alter this file, all the necessary chages to make the network drive be recognized were already made in other files.

# 6)
Creating the image:

run a cmd (on the project root) with a variation of this command line:

docker build -t user/image_name:tag --platform linux/amd64 .

e.g.
docker build -t pareskomon/runpod-xr-svrlss:ni --platform linux/amd64 .

after the image is built, upload it to the dockerhub using:

docker push user/image_name:tag

then you may add this image to the Runpod when creating the serverless endpoint (if you made a template first).
You may also chose to upload from other sources, but they will not be covered in this doc.

# 7)
There is already a snapshot and a test json here so feel free to explore and play with it.
useful links:
https://github.com/blib-la/runpod-worker-comfy

Now all you need is the http post in order to make requests.


---------------------------------------------\\--------------------------------------------

#Snapshot Issues and or technicalities.

Here are some issues about the snapshot that may break the proper way of working:

thge snapshot json may come in two parts, there is an example below:

{
    "comfyui": "2ff3104f70767a897e5468a0fe632fbd5a432b40",
    "git_custom_nodes": {
        "https://github.com/chrisgoringe/cg-use-everywhere": {
            "hash": "ce510b97d10e69d5fd0042e115ecd946890d2079",
            "disabled": false
        }
    },
    "cnr_custom_nodes": {
        "comfyui-logic": "1.0.0"
    },
  .
  .
  .
}

If the node is in "git_custom_nodes", then it will work properly and be inported normally when restoring the snapshot, but if it falls in the "cnr_custom_nodes" category, it will fail to be imported and the nodes will be unavalible in the desired workflow.

How to avoid/fix this? Well, in theoty this happens because these nodes were not imported via the Manager (although it was.. but Comfy did not recognize it T_T), but! all may not be lost yet, since, once again, in theory, this may be fixed ig there is a **.git folder** in the node folder. This way ComfyUI Manager can access the repository and download it consistently.

One way, although more manually is to install the nodes, and if any of them breaks, clone the repo from git into the project and then hit FixNode in the manager to ensure its working properly, this way it should not lose its reference and fix any problems.



#Newer Images

This repo already comes with a comfy and a linux and all is set accordingly, no need to wory, just add a snapshot and be happy.
This repos does NOT have any models listed in the folders of Extra_paths.yaml, but has the requirements of the models:

models/instantid/intantID_ip-adapter.bin
models/insightface/inswapper_128.onnx
models/insightface/models/antelopev2
models/insightface/models/buffalo_l
models/facerestore_models
models/facedetection
models/RMBG/RMBG-2.0

This repo already have a few nodes preinstalled, so no need to wory about them, here is the list:

"https://github.com/ltdrdata/ComfyUI-Manager"
"https://github.com/cubiq/ComfyUI_FaceAnalysis"
"https://github.com/chrisgoringe/cg-use-everywhere"
"https://github.com/BadCafeCode/masquerade-nodes-comfyui"
"https://github.com/aria1th/ComfyUI-LogicUtils"
"https://github.com/audioscavenger/ComfyUI-Thumbnails"
"https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes"
"https://github.com/WASasquatch/was-node-suite-comfyui"
"https://github.com/liusida/ComfyUI-AutoCropFaces"
"https://github.com/crystian/ComfyUI-Crystools"
"https://github.com/kijai/ComfyUI-KJNodes"
"https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
"https://github.com/jamesWalker55/comfyui-various"
"https://github.com/cubiq/ComfyUI_InstantID"
"https://github.com/sipherxyz/comfyui-art-venture"
"https://github.com/rgthree/rgthree-comfy"
"https://github.com/yolain/ComfyUI-Easy-Use"
"https://github.com/thecooltechguy/ComfyUI-ComfyWorkflows"
"https://github.com/chflame163/ComfyUI_LayerStyle"
"https://github.com/jags111/efficiency-nodes-comfyui"

glhf