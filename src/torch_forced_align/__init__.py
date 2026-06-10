import os as _os

import torch

from .forced_align import TokenSpan, forced_align, merge_tokens

# Loading the shared library registers torch.ops.torch_forced_align.forced_align
_lib_dir = _os.path.dirname(__file__)
_libs = [f for f in _os.listdir(_lib_dir) if f.startswith("_C") and f.endswith((".so", ".pyd", ".dylib"))]
if not _libs:
    raise ImportError("Could not find compiled _C extension in " + _lib_dir)
torch.ops.load_library(_os.path.join(_lib_dir, _libs[0]))
