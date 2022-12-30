from typing import Tuple

from dnaio import SequenceRecord

from .info import ModificationInfo

class BaseCounter:
    total_bp1: int
    total_bp2: int

    def count_bases_paired(
        self,
        __read1: SequenceRecord,
        __read2: SequenceRecord,
        __info1: ModificationInfo,
        __info2: ModificationInfo,
    ) -> Tuple[SequenceRecord, SequenceRecord]: ...
    def count_bases_single(
        self, __read1: SequenceRecord, __info1: ModificationInfo
    ) -> Tuple[SequenceRecord, SequenceRecord]: ...
