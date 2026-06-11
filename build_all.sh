#!/bin/bash

# Default CUDA arch list for the cpu/cu118 builds (sm_70 included; fine on CUDA 11/12).
DEFAULT_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0+PTX"

# Resolve the PyTorch index, matching CUDA toolkit, and arch list for a given
# torch version + CUDA major. The container CUDA must match the torch wheel's
# CUDA, and PyTorch shifts which minor it publishes per release (e.g. torch 2.12
# dropped cu128 for cu126); CUDA 13 also dropped Volta (sm_70), hence its
# trimmed arch list. Add a "<major>:<torch>" line to override the default for a
# specific version; the "<major>:*" line is the family default.
function resolve_cuda() {  # echoes "<index> <cuda_version> <arch_list>"
  local torch=$1 major=$2
  case "$major:$torch" in
    12:2.12) echo "cu126 12.6.3 7.0;7.5;8.0;8.6;8.9;9.0+PTX" ;;
    12:*)    echo "cu128 12.8.0 7.0;7.5;8.0;8.6;8.9;9.0+PTX" ;;
    13:*)    echo "cu130 13.2.0 7.5;8.0;8.6;8.9;9.0+PTX" ;;
  esac
}

# CUDA majors (wheel families) to build for a given torch version.
function cuda_majors_for() {  # echoes e.g. "12 13"
  local torch=$1
  local majors=(12)                        # every supported torch has CUDA 12 wheels
  [ "${torch#*.}" -ge 9 ] && majors+=(13)   # CUDA 13 wheels exist since torch 2.9
  echo "${majors[@]}"
}

function build_wheel() {
  local PYTHON_VERSION=$1
  local TORCH_VERSION=$2
  local TORCH_BACKEND=$3
  local VERSION_TAG=$4
  local CUDA_VERSION=${5:-12.8.0}
  local ARCH_LIST=${6:-$DEFAULT_ARCH_LIST}

  local IMAGE_TAG="torch-forced-align-py${PYTHON_VERSION//./-}-torch${TORCH_VERSION//./-}-${TORCH_BACKEND}"

  # Idempotent: skip if this wheel already exists in dist/. Match the normalized
  # local-version label (+torch2-12-cu12 -> +torch2.12.cu12) and the ABI tag.
  local norm_tag="${VERSION_TAG#+}"; norm_tag="${norm_tag//-/.}"
  local existing=( dist/*"+${norm_tag}-cp${PYTHON_VERSION//./}-"*.whl )
  if [ -e "${existing[0]}" ]; then
    echo "Skipping Python $PYTHON_VERSION, $VERSION_TAG — already built (${existing[0]##*/})" >&2
    return 0
  fi

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
  for torch_version in 2.7.0 2.8.0 2.9.0 2.10.0 2.11.0 2.12.0; do
    torch_major_minor=${torch_version%.*}
    torch_tag=torch${torch_major_minor//./-}
    build_wheel $python_version $torch_version cpu "+${torch_tag}-cpu"

    for cuda_major in $(cuda_majors_for "$torch_major_minor"); do
      read -r index cuda_version arch_list <<< "$(resolve_cuda "$torch_major_minor" "$cuda_major")"
      build_wheel $python_version $torch_version "$index" "+${torch_tag}-cu${cuda_major}" "$cuda_version" "$arch_list"
    done
  done

  torch_version=2.7.0
  torch_tag=torch2-7
  build_wheel $python_version $torch_version cu118 "+${torch_tag}-cu118" 11.8.0
done
