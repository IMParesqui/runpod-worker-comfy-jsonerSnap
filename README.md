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

# 5)To use the Network drive in the pods just add it while creating the serverless endpoint.
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

run a cmd with a variation of this command line:

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