# torch_forced_align

Standalone distribution of [torchaudio]'s CTC
[**forced alignment**][forced_align] op (`torchaudio.functional.forced_align`),
with builds for various PyTorch and CUDA versions, so that you can use it without pulling in
torchaudio and without locking in a specific PyTorch version.

[torchaudio]: https://github.com/pytorch/audio
[forced_align]: https://docs.pytorch.org/audio/main/generated/torchaudio.functional.forced_align.html

## Installation

Prebuilt wheels are published for **Python 3.10–3.13** and **PyTorch 2.7–2.12**
(CPU, CUDA 11.8, CUDA 12, CUDA 13). Pick the wheel matching the PyTorch already
in your environment – the **[install picker](https://cifkao.github.io/torch_forced_align/)**
builds the exact command for you.

In general, point your installer at the index for your PyTorch version + backend, e.g. for PyTorch 2.9 with CUDA 12.x:

```bash
pip install torch-forced-align \
  --extra-index-url https://cifkao.github.io/torch_forced_align/whl/torch2.9.cu12/
```

## Usage

Usage is identical to [`torchaudio.functional.forced_align`][forced_align]:

```python
from torch_forced_align import forced_align
import torch

log_probs = torch.randn(1, 50, 30).log_softmax(-1)
targets = torch.tensor([[1, 3, 5, 2]])

paths, scores = forced_align(log_probs, targets, blank=0)
```

The op itself lives at `torch.ops.torch_forced_align.forced_align`; the above function is a thin wrapper around it,
just like in torchaudio.

## Building from source

Wheels are built using `./build_all.sh`, via a Docker container for each wheel.

## License

[BSD 2-Clause](LICENSE)
