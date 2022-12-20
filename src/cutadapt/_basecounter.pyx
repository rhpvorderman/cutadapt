# cython: profile=False, emit_code_comments=False, language_level=3

from cpython.unicode cimport PyUnicode_GET_LENGTH
from cpython.tuple cimport PyTuple_GET_SIZE, PyTuple_GET_ITEM
from cpython.object cimport PyObject_GetAttr

cdef class PairedBaseCounter:
    cdef readonly Py_ssize_t total_bp1
    cdef readonly Py_ssize_t total_bp2
    cdef str _sequence_name

    def __cinit__(self):
        self.total_bp1 = 0
        self.total_bp2 = 0
        # PyObject_GetAttrString calls PyUnicode_FromString so we bypass that
        # and create the Unicode object once.
        self._sequence_name = "sequence"

    def count_bases(self, *args):
        cdef Py_ssize_t tup_size = PyTuple_GET_SIZE(args)
        cdef object read1
        cdef object read2
        cdef object seq1
        cdef object seq2
        if (tup_size) != 4:
            raise ValueError("Exactly two reads and their modifiers should be "
                             "given")
        read1 = <object>PyTuple_GET_ITEM(args, 0)
        read2 = <object>PyTuple_GET_ITEM(args, 1)
        seq1 = PyObject_GetAttr(read1, self._sequence_name)
        seq2 = PyObject_GetAttr(read2, self._sequence_name)
        self.total_bp1 += PyUnicode_GET_LENGTH(seq1)
        self.total_bp2 += PyUnicode_GET_LENGTH(seq2)
        return read1, read2
