# cython: language_level=3

from cpython.mem cimport PyMem_Malloc, PyMem_Free
from libc.string cimport memcpy, strstr
from cpython.unicode cimport PyUnicode_CheckExact, PyUnicode_GET_LENGTH
from libc.stdint cimport uint8_t, uint64_t

cdef extern from "Python.h":
    void *PyUnicode_DATA(object o)
    bint PyUnicode_IS_COMPACT_ASCII(object o)
    object PyUnicode_New(Py_ssize_t size, Py_UCS4 maxchar)

ctypedef struct KmerEntry:
    size_t kmer_offset
    ssize_t search_offset


cdef class KmerFinder:
    """
    Find kmers in strings. To replace the following code:

        kmers_and_offsets = [("AGA", -10), ("AGCATGA", 0)]
        for kmer, offset in kmers_and_offsets:
            sequence.find(kmer, offset)

    This has a lot of python overhead. The following code is equivalent:

        kmers_and_offsets = [("AGA", -10), ("AGCATGA", 0)]
        kmer_finder = KmerFinder(kmers_and_offsets)
        kmer_finder.kmers_present(sequence)

    This is more efficient as the kmers_present method can be applied to a lot
    of sequences and all the necessary unpacking for each kmer into C variables
    happens only once.
    """
    cdef:
        char *kmers
        KmerEntry *kmer_entries
        size_t number_of_kmers
        object kmers_and_offsets

    def __cinit__(self, kmers_and_offsets):
        self.kmers = NULL
        self.kmer_entries = NULL
        self.number_of_kmers = 0
        kmers = [kmer for kmer, _ in kmers_and_offsets]
        kmer_total_length = sum(len(kmer) for kmer in kmers)
        number_of_entries = len(kmers_and_offsets)
        self.kmer_entries = <KmerEntry *>PyMem_Malloc(number_of_entries * sizeof(KmerEntry))
        # for the kmers the NULL bytes also need space.
        self.kmers = <char *>PyMem_Malloc(kmer_total_length + number_of_entries)
        self.number_of_kmers = number_of_entries
        cdef size_t kmer_offset = 0
        cdef char *kmer_ptr
        cdef Py_ssize_t kmer_length
        for i, (kmer, offset) in enumerate(kmers_and_offsets):
            if not PyUnicode_CheckExact(kmer):
                raise TypeError(f"Kmer should be a string not {type(kmer)}")
            if not PyUnicode_IS_COMPACT_ASCII(kmer):
                raise ValueError("Only ASCII strings are supported")
            self.kmer_entries[i].kmer_offset = kmer_offset
            self.kmer_entries[i].search_offset  = offset
            kmer_length = PyUnicode_GET_LENGTH(kmer)
            kmer_ptr = <char *>PyUnicode_DATA(kmer)
            memcpy(self.kmers + kmer_offset, kmer_ptr, kmer_length)
            kmer_offset += kmer_length
            # NULL terminate each kmer in the kmer string as strstr only works
            # on NULL terminated strings.
            self.kmers[kmer_offset] = 0
            kmer_offset += 1
        self.kmers_and_offsets = kmers_and_offsets

    def __reduce__(self):
        return KmerFinder, (self.kmers_and_offsets,)

    def kmers_present(self, str sequence):
        cdef:
            KmerEntry entry
            size_t i
            size_t kmer_offset
            ssize_t search_offset
            char *kmer_ptr
            char *search_ptr
            char *search_result
        if not PyUnicode_IS_COMPACT_ASCII(sequence):
            raise ValueError("Only ASCII strings are supported")
        cdef char *seq = <char *>PyUnicode_DATA(sequence)
        cdef Py_ssize_t seq_length = PyUnicode_GET_LENGTH(sequence)
        for i in range(self.number_of_kmers):
            entry = self.kmer_entries[i]
            search_offset = entry.search_offset
            if search_offset < 0:
                search_offset = seq_length + search_offset
                if search_offset < 0:
                    search_offset = 0
            if search_offset > seq_length:
                continue
            kmer_offset = entry.kmer_offset
            kmer_ptr = self.kmers + kmer_offset
            search_ptr = seq + search_offset
            # memmem is 10-15% faster than strstr, but is not a C standard function.
            search_result = strstr(search_ptr, kmer_ptr)
            if search_result:
                return True
        return False

    def __dealloc__(self):
        PyMem_Free(self.kmers)
        PyMem_Free(self.kmer_entries)

# Upper and lower case
cdef uint8_t UPPER_CASE_MASK = 0b11011111
cdef uint64_t UPPER_CASE_MASK_8 = 0b11011111_11011111_11011111_11011111_11011111_11011111_11011111_11011111
def quick_and_dirty_upper(str sequence):
    """
    Quick and dirty convert to uppercase

    upper and lowercase ASCII alphabetic characters differ by just one bit
    that can be switched on or off. Problem is that this also switches some
    non-alphabetic characters. This function is for applications where this
    does not matter.
    """
    if not PyUnicode_IS_COMPACT_ASCII(sequence):
        raise ValueError(f"Sequence should be ASCII")
    cdef:
        Py_ssize_t length = PyUnicode_GET_LENGTH(sequence)
        object dest = PyUnicode_New(length, 127)
        uint8_t *src_ptr = <uint8_t *>PyUnicode_DATA(sequence)
        uint8_t *dest_ptr = <uint8_t *>PyUnicode_DATA(dest)
        uint64_t word
        Py_ssize_t word_length = 0
        size_t i = 0
        size_t j = 0
    # Take 8-byte chunks if possible
    # Max ensures we skip this trick for lengths below 8
    for i in range(0, max(0, length - 8), 8):
        word = (<uint64_t *>(src_ptr + i))[0]
        (<uint64_t *>(dest_ptr + i))[0] = word & UPPER_CASE_MASK_8
    for j in range(i, length):
        (dest_ptr + j)[0] = (src_ptr +j)[0] & UPPER_CASE_MASK
    return dest
