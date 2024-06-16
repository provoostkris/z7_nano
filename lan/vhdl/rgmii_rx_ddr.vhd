------------------------------------------------------------------------------
--  rgmii interfqce fifo with dual clock domain
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library unisim;
use     unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity rgmii_rx_ddr is
  port (
    rst         : in  std_logic;

    rgmii_rxc   : in  std_logic;
    rgmii_rx_ctl: in  std_logic;
    rgmii_rd    : in  std_logic_vector(3 downto 0);

    gmii_rx_dv  : out std_logic;
    gmii_rx_err : out std_logic;
    gmii_rd     : out std_logic_vector(7 downto 0)
    );

end entity rgmii_rx_ddr;
-------------------------------------------------------------------------------
architecture rtl of rgmii_rx_ddr is

  signal gmii_qr      : std_logic_vector(3 downto 0);
  signal gmii_qf      : std_logic_vector(3 downto 0);
  signal gmii_ctl_qr  : std_logic;
  signal gmii_ctl_qf  : std_logic;
  
begin

  -- interleave the DDR IO to a byte
  gmii_rd       <= gmii_qr & gmii_qf; 
  
  -- XOR for the error signal
  gmii_rx_err   <= gmii_ctl_qr xor gmii_ctl_qf;
  gmii_rx_dv    <= gmii_ctl_qr;
  
gen_io: for i in rgmii_rd'range generate

   -- IDDR: Double Data Rate Input Register with Set, Reset
   --       and Clock Enable.
   --       Artix-7
   -- Xilinx HDL Language Template, version 2023.1
   IDDR_inst : IDDR
   generic map (
      DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", -- "OPPOSITE_EDGE", "SAME_EDGE"
                                       -- or "SAME_EDGE_PIPELINED"
      INIT_Q1 => '0', -- Initial value of Q1: '0' or '1'
      INIT_Q2 => '0', -- Initial value of Q2: '0' or '1'
      SRTYPE => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC"
   port map (
      Q1 => gmii_qr(i), -- 1-bit output for positive edge of clock
      Q2 => gmii_qf(i), -- 1-bit output for negative edge of clock
      C => rgmii_rxc,   -- 1-bit clock input
      CE => '1', -- 1-bit clock enable input
      D => rgmii_rd(i),   -- 1-bit DDR data input
      R => rst,   -- 1-bit reset
      S => '0'    -- 1-bit set
      );

end generate gen_io;

   -- IDDR: Double Data Rate Input Register with Set, Reset
   --       and Clock Enable.
   --       Artix-7
   -- Xilinx HDL Language Template, version 2023.1
   IDDR_inst : IDDR
   generic map (
      DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", -- "OPPOSITE_EDGE", "SAME_EDGE"
                                       -- or "SAME_EDGE_PIPELINED"
      INIT_Q1 => '0', -- Initial value of Q1: '0' or '1'
      INIT_Q2 => '0', -- Initial value of Q2: '0' or '1'
      SRTYPE => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC"
   port map (
      Q1 => gmii_ctl_qr, -- 1-bit output for positive edge of clock
      Q2 => gmii_ctl_qf, -- 1-bit output for negative edge of clock
      C => rgmii_rxc,   -- 1-bit clock input
      CE => '1', -- 1-bit clock enable input
      D => rgmii_rx_ctl,   -- 1-bit DDR data input
      R => rst,   -- 1-bit reset
      S => '0'    -- 1-bit set
      );

end architecture rtl;
