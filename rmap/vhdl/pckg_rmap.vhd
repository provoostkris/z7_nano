-- ============================================================================
-- Title       : rmap_pkg
-- Description : Type definitions for ECSS RMAP decoder
-- Author      : Kris Provoost
-- ============================================================================

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

package pckg_rmap is

  -- ==========================================================================
  -- @brief RMAP_Fields_t
  --        Record containing decoded RMAP header fields
  -- ==========================================================================
  type RMAP_Fields_t is record
    target_logical   : std_logic_vector(7 downto 0);  --
    protocol_id      : std_logic_vector(7 downto 0);  --
    instruction      : std_logic_vector(7 downto 0);  --
    key              : std_logic_vector(7 downto 0);  --
    initiator_logical: std_logic_vector(7 downto 0);  --
    transaction_id   : std_logic_vector(15 downto 0); --
    ext_address      : std_logic_vector(7 downto 0);  --
    address          : std_logic_vector(31 downto 0); --
    data_length      : std_logic_vector(23 downto 0); --
  end record;


   function RMAP_CalculateCRC (
      constant INCRC:   in Std_Logic_Vector(7 downto 0);
      constant INBYTE:  in Std_Logic_Vector(7 downto 0))
      return               Std_Logic_Vector;

end package pckg_rmap;

package body pckg_rmap is

   -----------------------------------------------------------------------------
   -- Cyclic Redundancy Code (CRC) for Remote Memory Access Protocol (RMAP)
   -----------------------------------------------------------------------------
   -- Purpose:
   --    Given an intermediate SpaceWire RMAP CRC byte value and an RMAP header
   --    or data byte, return an updated RMAP CRC byte value.
   --
   -- Parameters:
   --    INCRC(7:0)  - The intermediate  RMAP CRC byte value.
   --    INBYTE(7:0) - The RMAP Header or Data byte.
   --
   -- Return value:
   --    OUTCRC(7:0) - The updated RMAP CRC byte value.
   --
   -- Description:
   --    One-to-many implementation: Galois version of LFSR (reverse CRC).
   --
   --         +---+   +---+   +---+   +---+   +---+   +---+    +---+    +---+
   -- out <-+-| 7 |<--| 6 |<--| 5 |<--| 4 |<--| 3 |<--| 2 |<-X-| 1 |<-X-| 0 |<-+
   --       | +---+   +---+   +---+   +---+   +---+   +---+  ^ +---+  ^ +---+  |
   --       |                                                |        |        |
   --       v                                                |        |        |
   -- in -->X------------------------------------------------+--------+--------+
   --    x**8     x**7    x**6    x**5    x**4    x**3    x**2     x**1     x**0
   --
   --    Generator polynomial: g(x) = x**8 + x**2 + x**1 + x**0
   --
   -- Notes:
   --    The INCRC input CRC value must have all bits zero for the first INBYTE.
   --
   --    The first INBYTE must be the first Header or Data byte covered by the
   --    RMAP CRC calculation. The remaining bytes must be supplied in the RMAP
   --    transmission/reception byte order.
   --
   --    If the last INBYTE is the last Header or Data byte covered by the RMAP
   --    CRC calculation then the OUTCRC output will be the RMAP CRC byte to be
   --    used for transmission or to be checked against the received CRC byte.
   --
   --    If the last INBYTE is the Header or Data CRC byte then the OUTCRC
   --    output will be zero if no errors have been detected and non-zero if
   --    an error has been detected.
   --
   --    Each byte is inserted in or extracted from a SpaceWire packet without
   --    the need for any bit reversal or similar manipulation. The SpaceWire
   --    packet transmission and reception procedure does the necessary bit
   --    ordering when sending and receiving Data Characters (see ECSS-E-ST-50-12).
   --
   --    SpaceWire data is sent/received Least Significant Bit (LSB) first:
   --       INBYTE(0) is the LSB of SpaceWire data byte (sent/received first)
   --       INCRC(0)  is the LSB of SpaceWire data byte (sent/received first)
   --
   -----------------------------------------------------------------------------
   function RMAP_CalculateCRC (
      constant INCRC:   in Std_Logic_Vector(7 downto 0);
      constant INBYTE:  in Std_Logic_Vector(7 downto 0))
      return               Std_Logic_Vector is  -- Same range as the two inputs
      -- This variable is to hold the output CRC value.
      variable OUTCRC:     Std_Logic_Vector(7 downto 0);
      -- Internal Linear Feedback Shift Register (LFSR). Note that the
      -- vector indices correspond to the powers of the Galois field
      -- polynomial g(x) which are NOT the same as the indices of the
      -- SpaceWire data byte.
      variable LFSR:       Std_Logic_Vector(7 downto 0);
   begin
      -- External to internal bit-order reversal to match indices.
      for i in 0 to 7 loop
         LFSR(7-i) := INCRC(i);
      end loop;
      -- Left shift LFSR eight times feeding in INBYTE bit 0 first (LSB).
      for j in 0 to 7 loop
         LFSR(7 downto 0) := (LFSR(6 downto 2)) &
                             (INBYTE(j) xor LFSR(7) xor LFSR(1)) &
                             (INBYTE(j) xor LFSR(7) xor LFSR(0)) &
                             (INBYTE(j) xor LFSR(7));
      end loop;
      -- Internal to external bit-order reversal to match indices.
      for i in 0 to 7 loop
         OUTCRC(7-i) := LFSR(i);
      end loop;
      -- Return the updated RMAP CRC byte value.
      return OUTCRC;
   end function RMAP_CalculateCRC;


end package body pckg_rmap;
