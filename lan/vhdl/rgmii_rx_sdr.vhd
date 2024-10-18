------------------------------------------------------------------------------
--  rgmii RX interface with single date rate I/O
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library unisim;
use     unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity rgmii_rx_sdr is
  port (
    rst         : in  std_logic;

    rgmii_rxc   : in  std_logic;
    rgmii_rx_ctl: in  std_logic;
    rgmii_rd    : in  std_logic_vector(3 downto 0);

    gmii_rx_dv  : out std_logic;
    gmii_rx_err : out std_logic;
    gmii_rx_ena : out std_logic;
    gmii_rx_lst : out std_logic;
    gmii_rd     : out std_logic_vector(7 downto 0)
    );

end entity rgmii_rx_sdr;
-------------------------------------------------------------------------------
architecture rtl of rgmii_rx_sdr is

  signal gmii         : std_logic_vector(7 downto 0);
  signal gmii_ctl_qr  : std_logic;
  signal gmii_ctl_qf  : std_logic;
  
  signal ctrl_rate    : std_logic;
  
begin
  
  --outputs assignments
  gmii_rx_ena <= ctrl_rate;
  gmii_rx_lst <= not rgmii_rx_ctl and gmii_ctl_qr;
  
  -- single rate sampling
  process(rst, rgmii_rxc) is
  begin
      if rst='1' then
        gmii     <= ( others => '0');
        gmii_rd  <= ( others => '0');
      elsif rising_edge(rgmii_rxc) then
        gmii(3 downto 0)  <= gmii(7 downto 4);
        gmii(7 downto 4)  <= rgmii_rd;
        gmii_rd           <= gmii; 
      end if;
  end process;
  
  -- control signals
  process(rst, rgmii_rxc) is
  begin
      if rst='1' then
        gmii_rx_err   <= '0';
        gmii_rx_dv    <= '0';
      elsif rising_edge(rgmii_rxc) then
        gmii_rx_err   <= gmii_ctl_qr xor gmii_ctl_qf;
        gmii_rx_dv    <= gmii_ctl_qr;
      end if;
  end process;
  
  -- rate control
  process(rst, rgmii_rxc) is
  begin
      if rst='1' then
        ctrl_rate       <= '0';
      elsif rising_edge(rgmii_rxc) then
        ctrl_rate       <= gmii_ctl_qr xor ctrl_rate;
      end if;
  end process;

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
