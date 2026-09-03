-- ============================================================================
-- Title       : RMAP_Decoder_AXI
-- Description : AXI4-Stream wrapper for ECSS RMAP decoder
-- Author      : Kris Provoost
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pckg_rmap.all;

entity RMAP_Decoder_AXI is
  Port (
    -- AXIS Input
    aclk            : in  std_logic;
    aresetn         : in  std_logic;
    s_axis_tvalid   : in  std_logic;
    s_axis_tdata    : in  std_logic_vector(7 downto 0);
    s_axis_tlast    : in  std_logic;
    s_axis_tready   : out std_logic;

    -- AXIS Output
    m_axis_tvalid   : out std_logic;
    m_axis_tdata    : out std_logic_vector(7 downto 0);
    m_axis_tlast    : out std_logic;
    m_axis_tready   : in  std_logic;

    -- Metadata
    packet_ready    : out std_logic;
    packet_error    : out std_logic;
    rmap_fields     : out RMAP_Fields_t
  );
end RMAP_Decoder_AXI;

architecture Behavioral of RMAP_Decoder_AXI is

  signal byte_valid    : std_logic;
  signal byte_in       : std_logic_vector(7 downto 0);
  signal byte_last     : std_logic;
  signal payload_valid : std_logic;
  signal payload_out   : std_logic_vector(7 downto 0);
  signal payload_end   : std_logic;

begin

  -- Drive input to core decoder
  byte_in    <= s_axis_tdata;
  byte_valid <= s_axis_tvalid and s_axis_tready;
  byte_last  <= s_axis_tvalid and s_axis_tlast;

  -- Input ready when decoder is ready to consume
  s_axis_tready <= '1'; -- Always ready (can be gated by FSM if needed)

  -- Instantiate core decoder
  decoder_inst: entity work.RMAP_Decoder
    port map (
      clk           => aclk,
      rstn          => aresetn,
      byte_in       => byte_in,
      byte_valid    => byte_valid,
      byte_last     => byte_last,
      packet_ready  => packet_ready,
      packet_error  => packet_error,
      rmap_fields   => rmap_fields,
      payload_out   => payload_out,
      payload_valid => payload_valid,
      payload_end   => payload_end
    );

  -- AXIS output logic
  m_axis_tdata  <= payload_out;
  m_axis_tvalid <= payload_valid;
  m_axis_tlast  <= payload_end;

end Behavioral;