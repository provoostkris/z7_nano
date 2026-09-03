## @file rmap_construct.py
# @brief Construct RMAP command packets and calculate ECSS CRC-8 values.
# @details
# Provides helpers for building WRITE and READ RMAP packets. The generated
# packets can be printed as VHDL byte literals for use in simulation
# testbenches.
# @author Kris Provoost
# @version 1.0

from typing import List
from enum import Enum

class RMAPCommand(Enum):
    """@brief Supported RMAP command types."""

    WRITE = 0x60
    READ = 0x40

def reverse_bits(byte: int) -> int:
    """@brief Reverse the bit order in one byte.

    @param byte Byte value to reverse.
    @return The byte with its bit order reversed.
    """
    return int('{:08b}'.format(byte)[::-1], 2)

def crc8_ecss(data: bytes) -> int:
    """@brief Calculate the ECSS RMAP CRC-8 for a byte sequence.

    @param data Bytes covered by the CRC.
    @return The calculated CRC value in the range 0x00 to 0xFF.
    """
    crc = 0x00
    for byte in data:
        byte = reverse_bits(byte)  # 🔁 Reverse bits before processing
        for i in range(8):
            din = (byte >> (7 - i)) & 0x01
            fb = ((crc >> 7) & 0x01) ^ din
            crc = ((crc << 1) & 0xFE)
            if fb:
                crc ^= 0x07
    return reverse_bits(crc)  # 🔁 Reverse final CRC byte

def build_rmap_packet(
    command: RMAPCommand,
    target_logical_address: int,
    initiator_logical_address: int,
    transaction_id: int,
    extended_address: int,
    memory_address: int,
    data: bytes = b"",
    read_length: int = 0,  # ✅ For READ commands
    verify: bool = False,
    reply_expected: bool = True,
    increment: bool = False
) -> bytes:
    """@brief Build an RMAP command packet.

    The packet contains the RMAP command header, a payload for WRITE
    commands, and a data CRC for WRITE commands. READ commands contain
    the requested length in the header and do not include a data payload.

    @param command RMAP command type to encode.
    @param target_logical_address Destination logical address.
    @param initiator_logical_address Source logical address.
    @param transaction_id Transaction identifier, encoded as two bytes.
    @param extended_address Extended memory address byte.
    @param memory_address 32-bit memory address.
    @param data Payload bytes for a WRITE command.
    @param read_length Number of bytes requested by a READ command.
    @param verify Set the verify bit in the instruction byte.
    @param reply_expected Set the reply-expected bit in the instruction byte.
    @param increment Set the address-increment bit in the instruction byte.
    @return The complete RMAP packet as immutable bytes.
    """
    header = bytearray()
    header.append(target_logical_address)
    header.append(0x01)  # Protocol Identifier
    header.append(command.value |   (0x04 if increment else 0x00) |
                                    (0x08 if reply_expected else 0x00) |
                                    (0x10 if verify else 0x00))
    header.append(0x00)  # Reserved
    header.append(initiator_logical_address)
    header.append((transaction_id >> 8) & 0xFF)
    header.append(transaction_id & 0xFF)
    header.append(extended_address)
    header += memory_address.to_bytes(4, 'big')

    # 🧮 Length field: payload for WRITE, requested length for READ
    length_field = len(data) if command == RMAPCommand.WRITE else read_length
    header += length_field.to_bytes(3, 'big')

    header.append(crc8_ecss(header))  # Header CRC

    packet = header + data
    if command == RMAPCommand.WRITE:
        packet.append(crc8_ecss(data))  # Data CRC

    return bytes(packet)



# 🧪 Demo Packets
def demo_packets():
    """@brief Print example WRITE and READ packets as VHDL byte literals."""
    print("🔧 Write Packet:")
    write_pkt = build_rmap_packet(
        command=RMAPCommand.WRITE,
        target_logical_address=0xFE,
        initiator_logical_address=0x67,
        transaction_id=0x0000,
        extended_address=0x00,
        memory_address=0xA0000000,
        data=bytes([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF,
                    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17]),
        verify=False,
        reply_expected=True,
        increment=True
    )
    log_pkt = write_pkt
    print(", ".join(f'x"{byte:02X}"' for byte in log_pkt) + ",")

    print("\n🔍 Read Packet:")
    read_pkt = build_rmap_packet(
        command=RMAPCommand.READ,
        target_logical_address=0xFE,
        initiator_logical_address=0x67,
        transaction_id=0x0001,
        extended_address=0x00,
        memory_address=0xA0000000,
        read_length=16,
        increment=True
    )
    log_pkt = read_pkt
    print(", ".join(f'x"{byte:02X}"' for byte in log_pkt) + ",")

if __name__ == "__main__":
    demo_packets()
