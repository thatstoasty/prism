# This code is based on https://github.com/tkaitchuck/aHash

from math.bit import bswap
from math.math import rotate_bits_left

alias U256 = SIMD[DType.uint64, 4]
alias U128 = SIMD[DType.uint64, 2]
alias MULTIPLE = 6364136223846793005
alias ROT = 23


@always_inline
fn folded_multiply(s: UInt64, by: UInt64) -> UInt64:
    var b1 = s * bswap(by)
    var b2 = bswap(s) * (~by)
    return b1 ^ bswap(b2)


@always_inline
fn read_small(data: DTypePointer[DType.uint8], length: Int) -> U128:
    if length >= 2:
        if length >= 4:
            # len 4-8
            var a = data.bitcast[DType.uint32]().load().cast[DType.uint64]()
            var b = data.offset(length - 4).bitcast[DType.uint32]().load().cast[DType.uint64]()
            return U128(a, b)
        else:
            var a = data.bitcast[DType.uint16]().load().cast[DType.uint64]()
            var b = data.offset(length - 1).load().cast[DType.uint64]()
            return U128(a, b)
    else:
        if length > 0:
            var a = data.load().cast[DType.uint64]()
            return U128(a, a)
        else:
            return U128(0, 0)


struct AHasher:
    var buffer: UInt64
    var pad: UInt64
    var extra_keys: U128

    fn __init__(inout self, key: U256):
        var pi_key = key ^ U256(
            0x243F_6A88_85A3_08D3,
            0x1319_8A2E_0370_7344,
            0xA409_3822_299F_31D0,
            0x082E_FA98_EC4E_6C89,
        )
        self.buffer = pi_key[0]
        self.pad = pi_key[1]
        self.extra_keys = U128(pi_key[2], pi_key[3])

    @always_inline
    fn update(inout self, new_data: UInt64):
        self.buffer = folded_multiply(new_data ^ self.buffer, MULTIPLE)

    @always_inline
    fn large_update(inout self, new_data: U128):
        var combined = folded_multiply(new_data[0] ^ self.extra_keys[0], new_data[1] ^ self.extra_keys[1])
        self.buffer = rotate_bits_left[ROT]((self.buffer + self.pad) ^ combined)

    @always_inline
    fn short_finish(self) -> UInt64:
        return self.buffer + self.pad

    @always_inline
    fn finish(self) -> UInt64:
        var rot = self.buffer & 63
        var folded = folded_multiply(self.buffer, self.pad)
        return (folded << rot) | (folded >> (64 - rot))

    @always_inline
    fn write(inout self, data: DTypePointer[DType.uint8], length: Int):
        self.buffer = (self.buffer + length) * MULTIPLE
        if length > 8:
            if length > 16:
                var tail = data.offset(length - 16).bitcast[DType.uint64]().load[width=2]()
                self.large_update(tail)
                var offset = 0
                while length - offset > 16:
                    var block = data.offset(offset).bitcast[DType.uint64]().load[width=2]()
                    self.large_update(block)
                    offset += 16
            else:
                var a = data.bitcast[DType.uint64]().load()
                var b = data.offset(length - 8).bitcast[DType.uint64]().load()
                self.large_update(U128(a, b))
        else:
            var value = read_small(data, length)
            self.large_update(value)


@always_inline
fn ahash(s: String) -> UInt64:
    var length = len(s)
    var b = s._as_ptr().bitcast[DType.uint8]()
    var hasher = AHasher(U256(0, 0, 0, 0))

    if length > 8:
        hasher.write(b, length)
    else:
        var value = read_small(b, length)
        hasher.buffer = folded_multiply(value[0] ^ hasher.buffer, value[1] ^ hasher.extra_keys[1])
        hasher.pad = hasher.pad + length

    return hasher.finish()
