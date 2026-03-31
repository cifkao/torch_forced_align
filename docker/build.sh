#!/bin/bash
set -euo pipefail

rm -f dist/*.whl

. .venv/bin/activate

echo Building >&2
uv build --wheel --no-build-isolation -o dist

echo Installing dist/*.whl >&2
uv pip install dist/*.whl --force-reinstall

echo Testing dist/*.whl >&2
pytest tests -v

echo Copying dist/*.whl >&2
cp dist/*.whl /dist
