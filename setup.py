from setuptools import setup, Extension
import setuptools_scm  # noqa  Ensure it’s installed

extensions = [
    Extension("cutadapt._align", sources=["src/cutadapt/_align.pyx"]),
    Extension("cutadapt.qualtrim", sources=["src/cutadapt/qualtrim.pyx"],
              extra_compile_args=["-mavx2"]),
    Extension("cutadapt.info", sources=["src/cutadapt/info.pyx"]),
    Extension("cutadapt._kmer_finder", sources=["src/cutadapt/_kmer_finder.pyx"]),
]

setup(ext_modules=extensions)
