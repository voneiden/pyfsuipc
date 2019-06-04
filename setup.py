from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

setup(
    ext_modules = cythonize([
    Extension("pyfsuipc", sources=["pyfsuipc.pyx", "IPCuser.c"],
libraries=["advapi32", "user32", "kernel32", "ole32", "oleaut32", "gdi32",
"gdiplus", "imm32"])
    ])
)
