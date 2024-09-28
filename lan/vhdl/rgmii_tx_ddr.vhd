------------------------------------------------------------------------------
--  rgmii TX interface with double date rate I/O
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library unisim;
use     unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity rgmii_tx_ddr is
  port (
    rst         : in  std_logic;
    clk         : in  std_logic;
    
    ref_clk     : in  std_logic;

    gmii_td     : in  std_logic_vector(7 downto 0);
    gmii_tx_en  : in  std_logic;
    gmii_tx_err : in  std_logic;

    rgmii_txc   : out std_logic;
    rgmii_tx_ctl: out std_logic;
    rgmii_td    : out std_logic_vector(3 downto 0)
    );

end entity rgmii_tx_ddr;
-------------------------------------------------------------------------------
architecture rtl of rgmii_tx_ddr is

  signal gmii_qr      : std_logic_vector(3 downto 0);
  signal gmii_qf      : std_logic_vector(3 downto 0);
  signal gmii_ctl_qr  : std_logic;
  signal gmii_ctl_qf  : std_logic;

  attribute IODELAY_GROUP : STRING;
  -- attribute IODELAY_GROUP of gen_io[0].ODDR_inst  : label is "rgmii_tx_dly";
  -- attribute IODELAY_GROUP of gen_io[1].ODDR_inst  : label is "rgmii_tx_dly";
  -- attribute IODELAY_GROUP of gen_io[2].ODDR_inst  : label is "rgmii_tx_dly";
  -- attribute IODELAY_GROUP of gen_io[3].ODDR_inst  : label is "rgmii_tx_dly";
  attribute IODELAY_GROUP of i_rgmii_tx_ctl       : label is "rgmii_tx_dly";
  attribute IODELAY_GROUP of i_rgmii_txc          : label is "rgmii_tx_dly";

begin

  -- interleave the DDR IO to a byte
  gmii_qr <= gmii_td(3 downto 0);
  gmii_qf <= gmii_td(7 downto 4);

  -- XOR for the error signal
  gmii_ctl_qr   <= gmii_tx_en;
  gmii_ctl_qf   <= gmii_tx_en xor gmii_tx_err;

gen_io: for i in rgmii_td'range generate

   -- ODDR: Output Double Data Rate Output Register with Set, Reset
   --       and Clock Enable.
   --       Artix-7
   -- Xilinx HDL Language Template, version 2023.1

   ODDR_inst : ODDR
   generic map(
      DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
      INIT => '0',   -- Initial value for Q port ('1' or '0')
      SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
   port map (
      Q => rgmii_td(i),   -- 1-bit DDR output
      C => clk,    -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D1 => gmii_qr(i),  -- 1-bit data input (positive edge)
      D2 => gmii_qf(i),  -- 1-bit data input (negative edge)
      R => rst,    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

end generate gen_io;

   -- ODDR: Output Double Data Rate Output Register with Set, Reset
   --       and Clock Enable.
   --       Artix-7
   -- Xilinx HDL Language Template, version 2023.1

   i_rgmii_tx_ctl : ODDR
   generic map(
      DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
      INIT => '0',   -- Initial value for Q port ('1' or '0')
      SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
   port map (
      Q => rgmii_tx_ctl,   -- 1-bit DDR output
      C => clk,    -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D1 => gmii_ctl_qr,  -- 1-bit data input (positive edge)
      D2 => gmii_ctl_qf,  -- 1-bit data input (negative edge)
      R => rst,    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

   -- ODDR: Output Double Data Rate Output Register with Set, Reset
   --       and Clock Enable.
   --       Artix-7
   -- Xilinx HDL Language Template, version 2023.1

   i_rgmii_txc : ODDR
   generic map(
      DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
      INIT => '0',   -- Initial value for Q port ('1' or '0')
      SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
   port map (
      Q => rgmii_txc,   -- 1-bit DDR output
      C => clk,    -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D1 => '1',  -- 1-bit data input (positive edge)
      D2 => '0',  -- 1-bit data input (negative edge)
      R => rst,    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

   -- IDELAYCTRL: IDELAYE2/ODELAYE2 Tap Delay Value Control
   --             Artix-7
   -- Xilinx HDL Language Template, version 2023.1

   IDELAYCTRL_inst : IDELAYCTRL
   port map (
      RDY => open,       -- 1-bit output: Ready output
      REFCLK => ref_clk, -- 1-bit input: Reference clock input
      RST => rst        -- 1-bit input: Active high reset input
   );


end architecture rtl;