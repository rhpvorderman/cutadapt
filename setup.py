from setuptools import setup, Extension
import setuptools_scm  # noqa  Ensure it’s installed

extensions = [
    Extension("cutadapt._align", sources=["src/cutadapt/_align.pyx"], libraries=["profiler"]),
    Extension("cutadapt.qualtrim", sources=["src/cutadapt/qualtrim.pyx"]),
]

setup(ext_modules=extensions)
