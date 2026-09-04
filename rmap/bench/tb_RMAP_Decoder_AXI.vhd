-- ============================================================================
-- Title       : tb_RMAP_Decoder_AXI
-- Description : Testbench for AXI4-Stream RMAP Decoder
-- Author      : Kris Provoost
-- ============================================================================
-- Functional Summary:
-- - Drives a valid RMAP command packet into AXIS input
-- - Monitors AXIS output stream
-- - Checks CRC status and decoded fields
-- - Prints results to console
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pckg_rmap.all;

entity tb_RMAP_Decoder_AXI is
end tb_RMAP_Decoder_AXI;

architecture Behavioral of tb_RMAP_Decoder_AXI is

  -- Clock and reset
  signal aclk      : std_logic := '0';
  signal aresetn   : std_logic := '0';

  -- AXIS input
  signal s_axis_tvalid : std_logic;
  signal s_axis_tdata  : std_logic_vector(7 downto 0);
  signal s_axis_tlast  : std_logic;
  signal s_axis_tready : std_logic;

  -- AXIS output
  signal m_axis_tvalid : std_logic;
  signal m_axis_tdata  : std_logic_vector(7 downto 0);
  signal m_axis_tlast  : std_logic;
  signal m_axis_tready : std_logic := '1';

  -- Metadata
  signal packet_ready  : std_logic;
  signal packet_error  : std_logic;
  signal rmap_fields   : RMAP_Fields_t;

  -- Stimulus packet (valid RMAP command)
  type ByteArray is array (natural range <>) of std_logic_vector(7 downto 0);
  constant rmap_packet : ByteArray := (
    x"FE", -- Target logical address
    x"01", -- Protocol Id
    x"6C", -- instruction
    x"00", -- key
    x"67", -- Initiator logical address
    x"00", x"00", -- Transaction ID
    x"00", -- extended address
    x"A0", x"00", x"00", x"00", -- Address
    x"00", x"00", x"10", -- Data length
    x"9F", -- Correct CRC-8
    x"01", x"23", x"45", x"67",
    x"89", x"AB", x"CD", x"EF",
    x"10", x"11", x"12", x"13",
    x"14", x"15", x"16", x"17",
    x"56" -- Correct CRC-8
  );

--   https://ecss.nl/wp-content/uploads/standards/ecss-e/ECSS-E-ST-50-52C5February2010.pdf
--   See Annex A.4 for commands
-- Target Logical Address: 0xFE
-- Protocol Identifier:  0x01
-- Instruction: 0x6C
-- Key:    0x00
-- Initiator Logical Address:  0x67
-- Transaction Identifier MS:  0x00
-- Transaction Identifier LS:  0x00
-- Extended Address:  0x00
-- Address MS:   0xA0
-- Address:      0x00
-- Address:      0x00
-- Address LS:   0x00
-- Data Length MS:   0x00
-- Data Length:      0x00
-- Data Length LS:   0x10
-- Header CRC:   0x9F
-- Data:    0x01
-- Data:    0x23
-- Data:    0x45
-- Data:    0x67
-- Data:    0x89
-- Data:    0xAB
-- Data:    0xCD
-- Data:    0xEF
-- Data:    0x10
-- Data:    0x11
-- Data:    0x12
-- Data:    0x13
-- Data:    0x14
-- Data:    0x15
-- Data:    0x16
-- Data:    0x17
-- Data CRC:   0x56

-- Target Logical Address:  0xFE
-- Protocol Identifier:  0x01
-- Instruction:   0x4C
-- Key:    0x00
-- Initiator Logical Address:  0x67
-- Transaction Identifier MS:  0x00
-- Transaction Identifier LS:  0x01
-- Extended Address:  0x00
-- Address MS:   0xA0
-- Address:    0x00
-- Address:    0x00
-- Address LS:   0x00
-- Data Length MS:   0x00
-- Data Length:   0x00
-- Data Length LS:   0x10
-- Header CRC:   0xC9

begin

  -- Clock generation
  clk_proc: process
  begin
    aclk <= '0';
    wait for 5 ns;
    aclk <= '1';
    wait for 5 ns;
  end process;

  -- DUT instantiation
  DUT: entity work.RMAP_Decoder_AXI
    port map (
      aclk           => aclk,
      aresetn        => aresetn,
      s_axis_tvalid  => s_axis_tvalid,
      s_axis_tdata   => s_axis_tdata,
      s_axis_tlast   => s_axis_tlast,
      s_axis_tready  => s_axis_tready,
      m_axis_tvalid  => m_axis_tvalid,
      m_axis_tdata   => m_axis_tdata,
      m_axis_tlast   => m_axis_tlast,
      m_axis_tready  => m_axis_tready,
      packet_ready   => packet_ready,
      packet_error   => packet_error,
      rmap_fields    => rmap_fields
    );

  -- Stimulus process
  stim_proc: process
  begin
    -- Reset
    aresetn <= '0';

    s_axis_tvalid <= '0';
    s_axis_tlast  <= '0';
    s_axis_tdata  <= ( others => '0');

    wait for 20 ns;
    wait until rising_edge(aclk);
    aresetn <= '1';
    wait for 20 ns;
    wait until rising_edge(aclk);

    -- Drive packet
    for i in rmap_packet'range loop
      s_axis_tdata  <= rmap_packet(i);
      s_axis_tvalid <= '1';
      if i = rmap_packet'high then
        s_axis_tlast <= '1';
      else
        s_axis_tlast <= '0';
      end if;
      wait until rising_edge(aclk) and s_axis_tready = '1';
    end loop;

    s_axis_tvalid <= '0';
    s_axis_tlast <= '0';

    -- Wait for decoder to finish
    wait until packet_ready = '1';

    -- Report results
    report "Decoded RMAP Packet:" & LF &
           "  Target Addr     : " & to_hstring(rmap_fields.target_logical) & LF &
           "  Protocol ID     : " & to_hstring(rmap_fields.protocol_id) & LF &
           "  Instruction     : " & to_hstring(rmap_fields.instruction) & LF &
           "  Key             : " & to_hstring(rmap_fields.key) & LF &
           "  Initiator Addr  : " & to_hstring(rmap_fields.initiator_logical) & LF &
           "  Transaction ID  : " & to_hstring(rmap_fields.transaction_id) & LF &
           "  Ext Address     : " & to_hstring(rmap_fields.ext_address) & LF &
           "  Address         : " & to_hstring(rmap_fields.address) & LF &
           "  Data Length     : " & to_hstring(rmap_fields.data_length) & LF &
           "  Packet Ready    : " & std_logic'image(packet_ready) & LF &
           "  Packet Error    : " & std_logic'image(packet_error) ;

    wait for 100 ns;
    report "Testbench complete.";
    wait;
  end process;


  time_out: process
  begin
    wait for 500 ns;
    report "Time out expired." severity note;
    std.env.stop;
  end process;

end Behavioral;
