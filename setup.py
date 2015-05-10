from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

setup(
    ext_modules = cythonize([
    Extension("*", ["*.pyx"],
              include_dirs=['./include'],
              library_dirs=['./lib'],
              libraries=["FSUIPC_User"])
    ])
)
