#!/usr/bin/env python3
"""
Convert Xilinx .bit file to byte-swapped raw .bin for Linux fpga_manager.

.bit format:
  - Header (variable length, ASCII metadata fields)
  - Sync word 0xAA995566 marks start of payload
  - Payload: configuration bitstream, big-endian 32-bit words

fpga_manager (Zynq) expects:
  - Raw bitstream payload starting at sync word
  - 32-bit words BYTE-SWAPPED (little-endian)

Strategy:
  1. Read .bit file
  2. Find sync word 0xAA995566 (big-endian as it appears in file)
     Note: in .bit file, sync word appears as bytes AA 99 55 66
  3. Take everything from sync word to end
  4. Byte-swap each 32-bit word
  5. Write to .bin
"""
import struct
import sys

def bit_to_bin(bit_path, bin_path):
    with open(bit_path, 'rb') as f:
        data = f.read()

    # Sync word in .bit file (big-endian): AA 99 55 66
    sync = b'\xaa\x99\x55\x66'
    idx = data.find(sync)
    if idx < 0:
        print(f"ERROR: sync word not found in {bit_path}")
        sys.exit(1)
    print(f"Sync word found at offset {idx} (0x{idx:x})")

    payload = data[idx:]
    # Pad to 4-byte boundary
    if len(payload) % 4:
        payload += b'\x00' * (4 - len(payload) % 4)

    # Byte-swap each 32-bit word: BE -> LE
    n_words = len(payload) // 4
    words_be = struct.unpack(f'>{n_words}I', payload)
    swapped = struct.pack(f'<{n_words}I', *words_be)

    with open(bin_path, 'wb') as f:
        f.write(swapped)

    print(f"Wrote {len(swapped)} bytes to {bin_path}")
    print(f"Input  size: {len(data)} bytes (.bit)")
    print(f"Output size: {len(swapped)} bytes (.bin)")
    print(f"Header stripped: {idx} bytes")

if __name__ == '__main__':
    bit_to_bin(sys.argv[1], sys.argv[2])
