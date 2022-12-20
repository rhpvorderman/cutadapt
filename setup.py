from setuptools import setup, Extension
import setuptools_scm  # noqa  Ensure it’s installed

extensions = [
    Extension("cutadapt._align", sources=["src/cutadapt/_align.pyx"]),
    Extension("cutadapt.qualtrim", sources=["src/cutadapt/qualtrim.pyx"]),
    Extension("cutadapt.info", sources=["src/cutadapt/info.pyx"]),
    Extension("cutadapt._basecounter", sources=["src/cutadapt/_basecounter.pyx"])
]

setup(ext_modules=extensions)
