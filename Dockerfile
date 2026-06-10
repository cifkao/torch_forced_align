ARG CUDA_VERSION=12.8.0
ARG PYTHON_VERSION=3.10
ARG TORCH_VERSION=2.9.0
ARG TORCH_BACKEND=cu128
ARG VERSION_TAG=+torch2-9-cu12
ARG UBUNTU_VERSION=22.04

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}

ARG PYTHON_VERSION
ARG TORCH_VERSION
ARG TORCH_BACKEND
ARG VERSION_TAG

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common gpg-agent && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} python${PYTHON_VERSION}-dev \
        python3-pip git ninja-build && \
    rm -rf /var/lib/apt/lists/*

RUN pip install uv

WORKDIR /build

COPY pyproject.toml setup.py ./
COPY src/ src/

RUN uv venv --python python${PYTHON_VERSION} .venv

# Patch version with tags, add dependency on the correct torch wheel
RUN . .venv/bin/activate && \
    BASE_VERSION=$(uv version --short) && \
    uv version --frozen "${BASE_VERSION}${VERSION_TAG}" && \
    uv add --frozen --index "https://download.pytorch.org/whl/${TORCH_BACKEND}" "torch~=${TORCH_VERSION}"

RUN uv sync --dev --no-install-project

COPY docker/ docker/
COPY tests/ tests/

ENV TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0+PTX"

CMD ["./docker/build.sh"]
