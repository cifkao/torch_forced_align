ARG CUDA_VERSION=12.8.0
ARG PYTHON_VERSION=3.10
ARG TORCH_VERSION=2.9.0
ARG TORCH_TAG=cu128
ARG UBUNTU_VERSION=22.04

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}

ARG PYTHON_VERSION
ARG TORCH_VERSION
ARG TORCH_TAG

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common gpg-agent && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv \
        python3-pip git ninja-build && \
    rm -rf /var/lib/apt/lists/*

RUN pip install uv

WORKDIR /build

COPY pyproject.toml setup.py ./
COPY docker/ docker/
COPY src/ src/

RUN uv venv --python python${PYTHON_VERSION} .venv

RUN . .venv/bin/activate && \
    uv pip install torch==${TORCH_VERSION} setuptools

# Patch version with torch + CUDA tags, add dependency on the correct torch wheel
RUN . .venv/bin/activate && \
    BASE_VERSION=$(uv version --short) && \
    VERSION_TAG=$(python3 -c "import os; print('torch'+'.'.join([*os.environ['TORCH_VERSION'].split('.')[:2],os.environ['TORCH_TAG']]))") && \
    uv version --frozen "${BASE_VERSION}+${VERSION_TAG}" && \
    uv add --frozen "torch~=${TORCH_VERSION}"

ENV TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0+PTX"

CMD ["./docker/build.sh"]
