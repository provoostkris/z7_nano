------------------------------------------------------------------------------
--  pl ethernet via lan
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_misc.all;

library unisim;
use     unisim.vcomponents.all;

library work;
use     work.lan_pkg.all;

entity lan is
  generic (
    my_mac            : std_logic_vector(47 downto 0) := x"02AABBCCDDEE"
  );
  port(
    clk               : in  std_logic;  --system clock
    reset_n           : in  std_logic;  --active low reset

    rgmii_rxc         : in  std_logic;
    rgmii_rx_ctl      : in  std_logic;
    rgmii_rd          : in  std_logic_vector(3 downto 0);
    rgmii_txc         : out std_logic;
    rgmii_tx_ctl      : out std_logic;
    rgmii_td          : out std_logic_vector(3 downto 0);
    phy_rst_n         : out std_logic;

    led               : out std_logic
  );
end lan;

architecture rtl of lan is

--! clock and reset tree signals
  signal  reset      : std_logic;
  signal  locked     : std_logic;
  signal  rst        : std_logic;
  signal  rst_n      : std_logic;
  signal  clkfb      : std_logic;
  signal  clk_eth   : std_logic;

--! signals on tx channel

  signal s_dat_tready  : std_logic;
  signal s_dat_tdata   : std_logic_vector(7 downto 0);
  signal s_dat_tlast   : std_logic;
  signal s_dat_tvalid  : std_logic;

  signal sof, eof     : std_logic;
  signal ctxdata      : std_logic_vector(7 downto 0);
  signal cgenframe    : std_logic;
  signal cgenframeack : std_logic;
  signal cenettxdata  : std_logic_vector(7 downto 0);
  signal cenettxen    : std_logic;
  signal cenettxerr   : std_logic;

--! signals on rx channel
  signal csof        : std_logic;
  signal ceof        : std_logic;
  signal cerrlen     : std_logic;
  signal cerrchecksum : std_logic;
  signal cpayloadlen : unsigned(15 downto 0);
  signal crxdata     : std_logic_vector(7 downto 0);
  signal crxdv       : std_logic;
  signal cenetrxdata : std_logic_vector(7 downto 0);
  signal cenetrxdv   : std_logic;
  signal cenetrxerr  : std_logic;


  attribute MARK_DEBUG : string;
  attribute MARK_DEBUG of sof           : signal is "TRUE";
  attribute MARK_DEBUG of eof           : signal is "TRUE";
  attribute MARK_DEBUG of cenettxdata   : signal is "TRUE";
  attribute MARK_DEBUG of cenettxen     : signal is "TRUE";
  attribute MARK_DEBUG of cenettxerr    : signal is "TRUE";

begin

  phy_rst_n <= '1';
  reset    <= not reset_n;
  rst      <= not locked;
  rst_n    <= not rst;

--! indicate the board is running
  i_pwm: entity work.pwm
  generic map (45)
  port    map (clk_eth, rst_n,led);

  --! send some dummy data , collected from a dummy frame
  process(rst_n, clk_eth) is
    variable v_idx : integer range 0 to c_pkg_dummy_eth'length;
  begin
      if rst_n='0' then
        v_idx         := 0;
        s_dat_tdata   <= ( others => '0');
        s_dat_tlast   <= '0';
        s_dat_tvalid  <= '0';
      elsif rising_edge(clk_eth) then
        if s_dat_tready = '1' then
          s_dat_tdata   <= c_pkg_dummy_eth(v_idx);
          s_dat_tvalid  <= '1';
          if v_idx = c_pkg_dummy_eth'high then
            s_dat_tlast   <= '1';
            v_idx         := 0;
          else
            s_dat_tlast   <= '0';
            v_idx         := v_idx + 1 ;
          end if;
        else
          s_dat_tdata   <= ( others => '0');
          s_dat_tlast   <= '0';
          s_dat_tvalid  <= '0';
        end if;
      end if;
  end process;

  --! user logic to tx_fifo
  i_rgmii_tx_fifo : entity work.rgmii_tx_fifo
    port map (
      s_clk         => clk_eth,
      s_rst_n       => rst_n,
      s_dat_tready  => s_dat_tready,
      s_dat_tdata   => s_dat_tdata ,
      s_dat_tlast   => s_dat_tlast ,
      s_dat_tvalid  => s_dat_tvalid,

      m_clk         => clk_eth,
      m_rst_n       => rst_n,
      m_txdata      => ctxdata,
      m_sof         => sof,
      m_eof         => eof,
      m_genframe    => cgenframe,
      m_genframeack => cgenframeack
    );

  --! tx_fifo to rgmii
  i_rgmii_tx : entity work.rgmii_tx
    port map (
      iclk         => clk_eth,
      irst_n       => rst_n,

      itxdata      => ctxdata,
      osof         => sof,
      ieof         => eof,
      igenframe    => cgenframe,
      ogenframeack => cgenframeack,

      otxdata      => cenettxdata,
      otxen        => cenettxen,
      otxerr       => cenettxerr
    );

  --! normal to reduced interface adapter
  i_gmii_to_rgmii: entity work.gmii_to_rgmii
    port map (
      idelay_clk   => '0',
      rst          => rst,
      gmii_txc     => clk_eth,
      gmii_tx_dv   => cenettxen,
      gmii_tx_err  => cenettxerr,
      gmii_td      => cenettxdata,
      rgmii_txc    => rgmii_txc   ,
      rgmii_tx_ctl => rgmii_tx_ctl,
      rgmii_td     => rgmii_td
    );

  i_rgmii_rx : entity work.rgmii_rx
    port map (
      -- iclk               => clk_eth,
      iclk               => rgmii_rxc,
      irst_n             => rst_n,

      irxdata            => cenetrxdata,
      irxdv              => cenetrxdv,
      irxer              => cenetrxerr,

      orxerr             => open,
      olenerr            => cerrlen,
      ochecksumerr       => cerrchecksum,
      opayloadlen        => cpayloadlen,

      imymac             => my_mac,

      osof               => csof,
      oeof               => ceof,
      orxdata            => crxdata,
      orxdv              => crxdv
    );

  --! reduced to normal interface adapter
  i_rgmii_rx_ddr: entity work.rgmii_rx_ddr
    port map(

      rst         => rst,

      rgmii_rxc   => rgmii_rxc,
      rgmii_rx_ctl=> rgmii_rx_ctl,
      rgmii_rd    => rgmii_rd    ,

      gmii_rx_dv  => cenetrxdv   ,
      gmii_rx_err => cenetrxerr  ,
      gmii_rd     => cenetrxdata
    );

--! we need a pll to make 125.0 mhz from the 50 mhz
--! that ratio is x2.5 , pll needs a number that is with a granularity off 0.125

   -- mmcme2_base: base mixed mode clock manager
   --              artix-7
   -- xilinx hdl language template, version 2023.1

   mmcme2_base_inst : mmcme2_base
   generic map (
      bandwidth => "optimized",  -- jitter programming (optimized, high, low)
      clkfbout_mult_f => 25.0,    -- multiply value for all clkout (2.000-64.000).
      clkfbout_phase => 0.0,     -- phase offset in degrees of clkfb (-360.000-360.000).
      clkin1_period => 20.0,      -- input clock period in ns to ps resolution (i.e. 33.333 is 30 mhz).
      -- clkout0_divide - clkout6_divide: divide amount for each clkout (1-128)
      clkout1_divide => 10,
      clkout2_divide => 1,
      clkout3_divide => 1,
      clkout4_divide => 1,
      clkout5_divide => 1,
      clkout6_divide => 1,
      clkout0_divide_f => 1.0,   -- divide amount for clkout0 (1.000-128.000).
      -- clkout0_duty_cycle - clkout6_duty_cycle: duty cycle for each clkout (0.01-0.99).
      clkout0_duty_cycle => 0.5,
      clkout1_duty_cycle => 0.5,
      clkout2_duty_cycle => 0.5,
      clkout3_duty_cycle => 0.5,
      clkout4_duty_cycle => 0.5,
      clkout5_duty_cycle => 0.5,
      clkout6_duty_cycle => 0.5,
      -- clkout0_phase - clkout6_phase: phase offset for each clkout (-360.000-360.000).
      clkout0_phase => 0.0,
      clkout1_phase => 0.0,
      clkout2_phase => 0.0,
      clkout3_phase => 0.0,
      clkout4_phase => 0.0,
      clkout5_phase => 0.0,
      clkout6_phase => 0.0,
      clkout4_cascade => false,  -- cascade clkout4 counter with clkout6 (false, true)
      divclk_divide => 1,        -- master division value (1-106)
      ref_jitter1 => 0.0,        -- reference input jitter in ui (0.000-0.999).
      startup_wait => false      -- delays done until mmcm is locked (false, true)
   )
   port map (
      -- clock outputs: 1-bit (each) output: user configurable clock outputs
      clkout0 => open, -- 1-bit output: clkout0
      clkout0b => open,   -- 1-bit output: inverted clkout0
      clkout1 => clk_eth,     -- 1-bit output: clkout1
      clkout1b => open,   -- 1-bit output: inverted clkout1
      clkout2 => open,     -- 1-bit output: clkout2
      clkout2b => open,   -- 1-bit output: inverted clkout2
      clkout3 => open,     -- 1-bit output: clkout3
      clkout3b => open,   -- 1-bit output: inverted clkout3
      clkout4 => open,     -- 1-bit output: clkout4
      clkout5 => open,     -- 1-bit output: clkout5
      clkout6 => open,     -- 1-bit output: clkout6
      -- feedback clocks: 1-bit (each) output: clock feedback ports
      clkfbout => clkfb,   -- 1-bit output: feedback clock
      clkfboutb => open, -- 1-bit output: inverted clkfbout
      -- status ports: 1-bit (each) output: mmcm status ports
      locked => locked,       -- 1-bit output: lock
      -- clock inputs: 1-bit (each) input: clock input
      clkin1 => clk,       -- 1-bit input: clock
      -- control ports: 1-bit (each) input: mmcm control ports
      pwrdwn => '0',       -- 1-bit input: power-down
      rst => reset,             -- 1-bit input: reset
      -- feedback clocks: 1-bit (each) input: clock feedback ports
      clkfbin => clkfb      -- 1-bit input: feedback clock
   );


end rtl;