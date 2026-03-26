import os
import platform

import torch
from setuptools import setup
from torch.utils.cpp_extension import BuildExtension, CppExtension, CUDAExtension

_PKG = "src/torch_forced_align"

_USE_CUDA = (
    os.environ.get("USE_CUDA", "").lower() not in ("0", "false", "off", "no")
    and torch.backends.cuda.is_built()
    and torch.version.hip is None
)

extra_compile_args = {
    "cxx": [],
}

if platform.system() != "Windows":
    extra_compile_args["cxx"].append("-fdiagnostics-color=always")

extension = CppExtension
sources = [
    f"{_PKG}/csrc/compute.cpp",
    f"{_PKG}/csrc/cpu/compute.cpp",
]

if _USE_CUDA:
    extension = CUDAExtension
    extra_compile_args["cxx"].append("-DUSE_CUDA")
    extra_compile_args["nvcc"] = ["-O2", "-DUSE_CUDA"]
    sources.append(f"{_PKG}/csrc/gpu/compute.cu")

setup(
    ext_modules=[
        extension(
            name="torch_forced_align._C",
            sources=sources,
            extra_compile_args=extra_compile_args,
            include_dirs=torch.utils.cpp_extension.include_paths(),
        ),
    ],
    cmdclass={"build_ext": BuildExtension.with_options(use_ninja=True)},
)
