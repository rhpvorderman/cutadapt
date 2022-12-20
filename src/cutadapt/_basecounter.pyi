from typing import Tuple

from dnaio import SequenceRecord

from .info import ModificationInfo

class PairedBaseCounter:
    total_bp1: int
    total_bp2: int

    def count_bases(self, __read1: SequenceRecord, __read2: SequenceRecord,
                    __info1: ModificationInfo, __info2: ModificationInfo
                    ) -> Tuple[SequenceRecord, SequenceRecord]: ...
