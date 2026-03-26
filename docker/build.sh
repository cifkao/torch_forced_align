#!/bin/bash
set -euo pipefail

. .venv/bin/activate

uv build --wheel --no-build-isolation -o /dist
