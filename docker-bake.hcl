variable "REGISTRY" {
    default = "docker.io"
}

variable "REGISTRY_USER" {
    default = "lucianoacirino"
}

variable "APP" {
    default = "comfyui"
}

variable "RELEASE" {
    default = "v0.3.44"
}

variable "BASE_IMAGE_REPOSITORY" {
    default = "ashleykza/runpod-base"
}

variable "BASE_IMAGE_VERSION" {
    default = "2.4.4"
}

group "default" {
    targets = ["cu128-py312"]
}

group "all" {
    targets = [
        "cu128-py312"
    ]
}

target "cu128-py312" {
    dockerfile = "Dockerfile"
    tags = ["${REGISTRY}/${REGISTRY_USER}/${APP}:cu128-py312-${RELEASE}"]
    args = {
        RELEASE                    = "${RELEASE}"
        BASE_IMAGE                 = "ashleykza/runpod-base:2.4.4-python3.12-cuda12.8.1-torch2.7.1"
        INDEX_URL                  = "https://download.pytorch.org/whl/cu128"
        TORCH_VERSION              = "2.7.1+cu128"
        XFORMERS_VERSION           = "0.0.31"
        COMFYUI_VERSION            = "${RELEASE}"
        APP_MANAGER_VERSION        = "1.2.2"
        CIVITAI_DOWNLOADER_VERSION = "2.1.0"
    }
    platforms = ["linux/amd64"]
}