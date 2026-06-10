#!/bin/bash

# Default CUDA arch list (CUDA 12). CUDA 13 dropped Volta (sm_70), so cu130
# builds pass a trimmed list.
DEFAULT_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0+PTX"
CUDA13_ARCH_LIST="7.5;8.0;8.6;8.9;9.0+PTX"

function build_wheel() {
  local PYTHON_VERSION=$1
  local TORCH_VERSION=$2
  local TORCH_BACKEND=$3
  local VERSION_TAG=$4
  local CUDA_VERSION=${5:-12.8.0}
  local ARCH_LIST=${6:-$DEFAULT_ARCH_LIST}

  local IMAGE_TAG="torch-forced-align-py${PYTHON_VERSION//./-}-torch${TORCH_VERSION//./-}-${TORCH_BACKEND}"

  echo "Building for Python $PYTHON_VERSION, PyTorch $TORCH_VERSION, backend $TORCH_BACKEND (version tag: $VERSION_TAG)" >&2
  docker build -t "$IMAGE_TAG" \
    --build-arg PYTHON_VERSION="$PYTHON_VERSION" \
    --build-arg TORCH_VERSION="$TORCH_VERSION" \
    --build-arg TORCH_BACKEND="$TORCH_BACKEND" \
    --build-arg VERSION_TAG="$VERSION_TAG" \
    --build-arg CUDA_VERSION="$CUDA_VERSION" . &&
  docker run --rm --gpus all -e TORCH_CUDA_ARCH_LIST="$ARCH_LIST" -v ./dist:/dist "$IMAGE_TAG"
  docker rmi "$IMAGE_TAG"
}

for python_version in 3.10 3.11 3.12 3.13; do
  for torch_version in 2.7.0 2.8.0 2.9.0 2.10.0 2.11.0; do
    torch_major_minor=${torch_version%.*}
    torch_minor=${torch_major_minor#*.}
    torch_tag=torch${torch_major_minor//./-}
    build_wheel $python_version $torch_version cpu "+${torch_tag}-cpu"
    build_wheel $python_version $torch_version cu128 "+${torch_tag}-cu12" 12.8.0
    # CUDA 13 PyTorch wheels only exist for torch >= 2.9.
    if [ "$torch_minor" -ge 9 ]; then
      build_wheel $python_version $torch_version cu130 "+${torch_tag}-cu13" 13.2.0 "$CUDA13_ARCH_LIST"
    fi
  done

  torch_version=2.7.0
  torch_tag=torch2-7
  build_wheel $python_version $torch_version cu118 "+${torch_tag}-cu118" 11.8.0
done
