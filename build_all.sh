#!/bin/bash

function build_wheel() {
  local PYTHON_VERSION=$1
  local TORCH_VERSION=$2
  local TORCH_TAG=$3
  local CUDA_VERSION=$4

  if [[ -z "$CUDA_VERSION" ]]; then
    CUDA_VERSION=12.8.0
  fi

  local IMAGE_TAG="torch-forced-align-py${PYTHON_VERSION//./-}-torch${TORCH_VERSION//./-}-${TORCH_TAG}"

  echo "Building for Python $PYTHON_VERSION, PyTorch $TORCH_VERSION+$TORCH_TAG" >&2
  docker build -t "$IMAGE_TAG" \
    --build-arg PYTHON_VERSION="$PYTHON_VERSION" \
    --build-arg TORCH_VERSION="$TORCH_VERSION" \
    --build-arg TORCH_TAG="$TORCH_TAG" . &&
  docker run --rm -v ./dist:/dist "$IMAGE_TAG"
  docker rmi "$IMAGE_TAG"
}

for python_version in 3.10 3.11 3.12; do
  for torch_version in 2.7.0 2.8.0 2.9.0 2.10.0 2.11.0; do
    build_wheel $python_version $torch_version cpu
    build_wheel $python_version $torch_version cu126 12.6.3
    build_wheel $python_version $torch_version cu128 12.8.0
  done

  torch_version=2.7.0
  build_wheel $python_version $torch_version cu118 11.8.0
done
