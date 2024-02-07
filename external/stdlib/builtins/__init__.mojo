"""
The stdlib extensions were pulled in from https://github.com/gabrieldemarmiesse/mojo-stdlib-extensions/tree/master!
I added a few convenience functions in the vector.mojo file, but the rest is from there.
"""

from external.stdlib.builtins._generic_list import list, list_to_str
from external.stdlib.builtins._bytes import bytes, to_bytes
from external.stdlib.builtins._hash import hash, Hashable, HashableCollectionElement, Equalable
from external.stdlib.builtins._dict import dict, HashableInt, HashableStr


fn hex(x: UInt8) -> String:
    alias hex_table: String = "0123456789abcdef"
    return "0x" + hex_table[(x >> 4).to_int()] + hex_table[(x & 0xF).to_int()]
