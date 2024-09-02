------------------------------------------------------------------------------
--  rgmii interfqce with double date rate I/O
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library unisim;
use     unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity rgmii_tx_sdr is
  port (
    rst          : in  std_logic;

    gmii_txc     : in  std_logic;
    gmii_tx_dv   : in  std_logic;
    gmii_tx_err  : in  std_logic;
    gmii_td      : in  std_logic_vector(7 downto 0);

    rgmii_txc    : in  std_logic;
    rgmii_tx_ctl : out std_logic;
    rgmii_td     : out std_logic_vector(3 downto 0)
    );

end entity rgmii_tx_sdr;
-------------------------------------------------------------------------------
architecture rtl of rgmii_tx_sdr is

  signal nibble  : std_logic;

  signal s_gmii_toggle  : std_logic;
  signal s_gmii_tx_dv   : std_logic;
  signal s_gmii_tx_err  : std_logic;
  signal s_gmii_td      : std_logic_vector(7 downto 0);
  signal s_gmii_tx_ctl  : std_logic;

begin

  -- sample between the 1:2 clocks
  process(rst, rgmii_txc) is
  begin
      if rst='1' then
        s_gmii_toggle  <= '0';
        s_gmii_tx_dv   <= '0';
        s_gmii_tx_err  <= '0';
        s_gmii_td      <= ( others => '0');
      elsif rising_edge(rgmii_txc) then
        s_gmii_toggle  <= not s_gmii_toggle;
        if s_gmii_toggle = '1' then
          s_gmii_tx_dv   <= gmii_tx_dv   ;
          s_gmii_tx_err  <= gmii_tx_err  ;
          s_gmii_td      <= gmii_td      ;
        end if;
      end if;
  end process;


  -- nibble transmission
  process(rst, rgmii_txc) is
  begin
      if rst='1' then
        rgmii_td  <= ( others => '0');
        nibble    <= '0';
      elsif rising_edge(rgmii_txc) then
        if s_gmii_tx_dv = '1' then
          case nibble is
            when '0'    => rgmii_td  <= s_gmii_td(3 downto 0);
            when others => rgmii_td  <= s_gmii_td(7 downto 4);
          end case;
          nibble <= not nibble;
        end if;
      end if;
  end process;

  -- control transmission

  s_gmii_tx_ctl <= s_gmii_tx_dv xor s_gmii_tx_err;

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
      Q => rgmii_tx_ctl,   -- 1-bit DDR output
      C => rgmii_txc,    -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D1 => s_gmii_tx_dv,  -- 1-bit data input (positive edge)
      D2 => s_gmii_tx_ctl,  -- 1-bit data input (negative edge)
      R => '0',    -- 1-bit reset input
      S => rst     -- 1-bit set input
   );

end architecture rtl;
