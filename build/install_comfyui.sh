#!/usr/bin/env bash
set -e

# Clone the repo
git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI
cd /ComfyUI
git checkout ${COMFYUI_VERSION}

# Create and activate the venv
python3 -m venv --system-site-packages venv
source venv/bin/activate

# Install torch, and xformers
pip3 install --no-cache-dir torch=="${TORCH_VERSION}" torchvision torchaudio --index-url ${INDEX_URL}
pip3 install --no-cache-dir xformers=="${XFORMERS_VERSION}" --index-url ${INDEX_URL}

# Install ComfyUI requirements
pip3 install -r requirements.txt
pip3 install accelerate
pip install setuptools --upgrade

# Custom node repository URLs
repos=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    "https://github.com/Ttl/ComfyUi_NNLatentUpscale"
    "https://github.com/ciri/comfyui-model-downloader"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch"
    "https://github.com/Acly/comfyui-inpaint-nodes"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/pamparamm/sd-perturbed-attention"
    "https://github.com/Fannovel16/comfyui_controlnet_aux"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/yolain/ComfyUI-Easy-Use"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/LucianoCirino/ComfyUI-invAIder-Nodes"
    "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
    "https://github.com/nkchocoai/ComfyUI-Dart"
    "https://github.com/chrisgoringe/cg-use-everywhere"
    "https://github.com/kijai/ComfyUI-segment-anything-2"
    "https://github.com/kijai/ComfyUI-Florence2"
)

# Loop through each repository
for repo in "${repos[@]}"; do
    echo "Installing $(basename "$repo")..."
    
    # Extract repo name from URL
    repo_name=$(basename "$repo")
    
    # Clone the repository
    git clone "$repo" "custom_nodes/$repo_name"
    
    # Check if requirements.txt exists and install dependencies
    if [ -f "custom_nodes/$repo_name/requirements.txt" ]; then
        echo "Installing requirements for $repo_name..."
        cd "custom_nodes/$repo_name"
        pip3 install -r requirements.txt
        cd ../..
    else
        echo "No requirements.txt found for $repo_name, skipping pip install"
    fi
    
    echo "Finished installing $repo_name"
done

# Clean pip cache at the end
pip3 cache purge
echo "All custom nodes installed successfully!"

# Install SageAttention2 from prebuilt wheel (no compilation needed)
pip install triton
cd ..
wget -nc https://huggingface.co/nitin19/flash-attention-wheels/resolve/main/sageattention-2.1.1-cp312-cp312-linux_x86_64.whl
pip install ./sageattention-2.1.1-cp312-cp312-linux_x86_64.whl

# Fix some incorrect modules
pip3 install numpy==1.26.4
deactivate
