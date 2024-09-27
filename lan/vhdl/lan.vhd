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

entity lan is
  generic (
    g_sim             : boolean := false;
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

    pll_lock          : out std_logic;
    led               : out std_logic;

    --! block design
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC
  );
end lan;

architecture rtl of lan is

--! clock and reset tree signals
  signal reset      : std_logic; --! inverted reset input port
  signal locked     : std_logic; --! lock output from the local PLL
  signal rst        : std_logic; --! PLL locked inverted
  signal rst_n      : std_logic; --! PLL locked copy
  signal clkfb      : std_logic; --! required feedback clock for PLL
  signal clk_eth    : std_logic; --! PLL output 125 MHz
  signal fclk_clk   : std_logic; --! exported clock from the PS
  signal clk_slow   : std_logic; --! PLL output  50 MHz
  signal clk_txfr   : std_logic; --! clock for transfer between PS and PL

--! signals on tx channel
  signal s_tx_dat_tready  : std_logic;
  signal s_tx_dat_tdata   : std_logic_vector(7 downto 0);
  signal s_tx_dat_tkeep   : std_logic_vector(0 downto 0);
  signal s_tx_dat_tlast   : std_logic;
  signal s_tx_dat_tvalid  : std_logic;
  signal s_tx_dat_tid     : std_logic_vector(0 downto 0);
  signal s_tx_dat_tdest   : std_logic_vector(0 downto 0);
  signal s_tx_dat_tuser   : std_logic_vector(0 downto 0);

  signal sof, eof     : std_logic;
  signal ctxdata      : std_logic_vector(7 downto 0);
  signal cgenframe    : std_logic;
  signal cgenframeack : std_logic;
  signal cenettxdata  : std_logic_vector(7 downto 0);
  signal cenettxen    : std_logic;
  signal cenettxerr   : std_logic;

--! signals on rx channel
  signal s_rx_dat_tready  : std_logic;
  signal s_rx_dat_tdata   : std_logic_vector(7 downto 0);
  signal s_rx_dat_tlast   : std_logic;
  signal s_rx_dat_tvalid  : std_logic;

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

--! signals for AXIS CH 0
  signal AXI_STR_RXD_0_tdata  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal AXI_STR_RXD_0_tkeep  : STD_LOGIC_VECTOR (  3 downto 0 );
  signal AXI_STR_RXD_0_tlast  : STD_LOGIC;
  signal AXI_STR_RXD_0_tready : STD_LOGIC;
  signal AXI_STR_RXD_0_tvalid : STD_LOGIC;
  signal AXI_STR_RXD_0_tid    : STD_LOGIC_VECTOR (  0 downto 0 );
  signal AXI_STR_RXD_0_tdest  : STD_LOGIC_VECTOR (  0 downto 0 );
  signal AXI_STR_RXD_0_tuser  : STD_LOGIC_VECTOR (  0 downto 0 );
  
  signal AXI_STR_RXD_DBG_tdata  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal AXI_STR_RXD_DBG_tkeep  : STD_LOGIC_VECTOR (  3 downto 0 );
  signal AXI_STR_RXD_DBG_tlast  : STD_LOGIC;
  signal AXI_STR_RXD_DBG_tready : STD_LOGIC;
  signal AXI_STR_RXD_DBG_tvalid : STD_LOGIC;
  signal AXI_STR_RXD_DBG_tid    : STD_LOGIC_VECTOR (  0 downto 0 );
  signal AXI_STR_RXD_DBG_tdest  : STD_LOGIC_VECTOR (  0 downto 0 );
  signal AXI_STR_RXD_DBG_tuser  : STD_LOGIC_VECTOR (  0 downto 0 );

  signal AXI_STR_TXD_0_tdata  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal AXI_STR_TXD_0_tlast  : STD_LOGIC;
  signal AXI_STR_TXD_0_tready : STD_LOGIC;
  signal AXI_STR_TXD_0_tvalid : STD_LOGIC;

  signal AXI_STR_TXD_DBG_tdata  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal AXI_STR_TXD_DBG_tlast  : STD_LOGIC;
  signal AXI_STR_TXD_DBG_tready : STD_LOGIC;
  signal AXI_STR_TXD_DBG_tvalid : STD_LOGIC;


--! spare signals on block design
  signal interrupt_0              :   STD_LOGIC;
  signal mm2s_prmry_reset_out_n_0 :   STD_LOGIC;
  signal s2mm_prmry_reset_out_n_0 :   STD_LOGIC;

  attribute MARK_DEBUG : string;

  -- attribute MARK_DEBUG of sof           : signal is "TRUE";
  -- attribute MARK_DEBUG of eof           : signal is "TRUE";
  -- attribute MARK_DEBUG of cenettxdata   : signal is "TRUE";
  -- attribute MARK_DEBUG of cenettxen     : signal is "TRUE";
  -- attribute MARK_DEBUG of cenettxerr    : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_RXD_0_tdata  : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_RXD_0_tlast  : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_RXD_0_tready : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_RXD_0_tvalid : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_TXD_0_tdata  : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_TXD_0_tlast  : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_TXD_0_tready : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_TXD_0_tvalid : signal is "TRUE";


begin

  phy_rst_n <= '1';
  reset    <= not reset_n;
  rst      <= not locked;
  rst_n    <=     locked;
  pll_lock <=     locked;

  gen_ps_clk: if g_sim = false generate
    clk_txfr <= fclk_clk;
  end generate;

  gen_pl_clk: if g_sim = true generate
    clk_txfr <= clk_slow;
  end generate;

--! indicate the board is running
  i_pwm: entity work.pwm
  generic map (45)
  port    map (clk_eth, rst_n,led);


  --! user logic with ROM
  i_rom_tx : entity work.rom_tx
    port map (
      clk           => clk_txfr,
      rst_n         => rst_n,
      m_dat_tready  => AXI_STR_TXD_DBG_tready,
      m_dat_tdata   => AXI_STR_TXD_DBG_tdata ,
      m_dat_tlast   => AXI_STR_TXD_DBG_tlast ,
      m_dat_tvalid  => AXI_STR_TXD_DBG_tvalid
    );

  i_axis_width_converter_tx : entity work.axis_adapter
    generic map (
      S_DATA_WIDTH    => 32,
      M_DATA_WIDTH    => 8
      )
    port map (
      -- Usual ports
      clk      => clk_txfr,
      rst      => rst,
      -- AXI stream input
      s_axis_tready => AXI_STR_TXD_0_tready,
      s_axis_tdata  => AXI_STR_TXD_0_tdata,
      s_axis_tkeep  => "1111",
      s_axis_tvalid => AXI_STR_TXD_0_tvalid,
      s_axis_tlast  => AXI_STR_TXD_0_tlast,
      s_axis_tid    => "1",
      s_axis_tdest  => "1",
      s_axis_tuser  => "1",
      -- AXI stream output
      m_axis_tready => s_tx_dat_tready,
      m_axis_tdata  => s_tx_dat_tdata,
      m_axis_tkeep  => s_tx_dat_tkeep,
      m_axis_tvalid => s_tx_dat_tvalid,
      m_axis_tlast  => s_tx_dat_tlast,
      m_axis_tid    => s_tx_dat_tid,
      m_axis_tdest  => s_tx_dat_tdest,
      m_axis_tuser  => s_tx_dat_tuser
    );

  --! user logic to tx_fifo
  i_rgmii_tx_fifo : entity work.rgmii_tx_fifo
    port map (
      s_clk         => clk_txfr,
      s_rst_n       => rst_n,
      s_dat_tready  => s_tx_dat_tready,
      s_dat_tdata   => s_tx_dat_tdata ,
      s_dat_tlast   => s_tx_dat_tlast ,
      s_dat_tvalid  => s_tx_dat_tvalid,

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

  --! RGMII TX PHY : normal to reduced interface adapter
  i_rgmii_tx_ddr: entity work.rgmii_tx_ddr
    port map (
      rst          => rst,
      clk          => clk_eth,

      gmii_td      => cenettxdata,
      gmii_tx_en   => cenettxen,
      gmii_tx_err  => cenettxerr,

      rgmii_txc    => rgmii_txc   ,
      rgmii_tx_ctl => rgmii_tx_ctl,
      rgmii_td     => rgmii_td
    );

  --! RGMII RX PHY : reduced to normal interface adapter
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

  --! ethernet frame reciever : check ethernet header
  i_eth_frm_rx : entity work.eth_frm_rx
    port map (
      iclk               => rgmii_rxc,
      irst_n             => rst_n,

      irxdata            => cenetrxdata,
      irxdv              => cenetrxdv,
      irxer              => cenetrxerr,

      orxerr             => open,
      olenerr            => cerrlen,
      ochecksumerr       => cerrchecksum,
      opayloadlen        => cpayloadlen,

      my_dest_mac        => my_mac,
      mac_match          => open,

      osof               => csof,
      oeof               => ceof,
      orxdata            => crxdata,
      orxdv              => crxdv
    );

  --! RX frame fifo : buffer before sending to block design
  i_eth_rx_fifo : entity work.eth_rx_fifo
    port map (
    s_clk         => rgmii_rxc,
    s_rst_n       => rst_n,
    s_sof         => csof,
    s_eof         => ceof,
    s_rxdata      => crxdata,
    s_rxdv        => crxdv,

    m_clk         => clk_txfr,
    m_rst_n       => rst_n,
    m_dat_tready  => s_rx_dat_tready,
    m_dat_tdata   => s_rx_dat_tdata,
    m_dat_tlast   => s_rx_dat_tlast,
    m_dat_tvalid  => s_rx_dat_tvalid
    );

  --! convert from byte to word
  i_axis_width_converter_rx : entity work.axis_adapter
    generic map (
      S_DATA_WIDTH    => 8,
      M_DATA_WIDTH   => 32
      )
    port map (
      -- Usual ports
      clk      => clk_txfr,
      rst      => rst,
      -- AXI stream input
      s_axis_tready => s_rx_dat_tready,
      s_axis_tdata  => s_rx_dat_tdata,
      s_axis_tkeep  => "1",
      s_axis_tvalid => s_rx_dat_tvalid,
      s_axis_tlast  => s_rx_dat_tlast,
      s_axis_tid    => "1",
      s_axis_tdest  => "1",
      s_axis_tuser  => "1",
      -- AXI stream output
      m_axis_tready => AXI_STR_RXD_0_tready,
      m_axis_tdata  => AXI_STR_RXD_0_tdata,
      m_axis_tkeep  => AXI_STR_RXD_0_tkeep,
      m_axis_tvalid => AXI_STR_RXD_0_tvalid,
      m_axis_tlast  => AXI_STR_RXD_0_tlast,
      m_axis_tid    => AXI_STR_RXD_0_tid,
      m_axis_tdest  => AXI_STR_RXD_0_tdest,
      m_axis_tuser  => AXI_STR_RXD_0_tuser
    );
    
    AXI_STR_RXD_DBG_tready <= '1';

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
      clkout2_divide => 25,
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
      clkout2 => clk_slow,     -- 1-bit output: clkout2
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


--! add the block design containing the processor
  bd_base_i: entity work.bd_base
    port map (

      FCLK_CLK0_0 => fclk_clk,

      AXI_STR_RXD_0_tdata(31 downto 0) => AXI_STR_RXD_0_tdata(31 downto 0),
      AXI_STR_RXD_0_tlast => AXI_STR_RXD_0_tlast,
      AXI_STR_RXD_0_tready => AXI_STR_RXD_0_tready,
      AXI_STR_RXD_0_tvalid => AXI_STR_RXD_0_tvalid,

      AXI_STR_TXD_0_tdata(31 downto 0) => AXI_STR_TXD_0_tdata(31 downto 0),
      AXI_STR_TXD_0_tlast => AXI_STR_TXD_0_tlast,
      AXI_STR_TXD_0_tready => AXI_STR_TXD_0_tready,
      AXI_STR_TXD_0_tvalid => AXI_STR_TXD_0_tvalid,

      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      interrupt_0 => interrupt_0,
      mm2s_prmry_reset_out_n_0 => mm2s_prmry_reset_out_n_0,
      s2mm_prmry_reset_out_n_0 => s2mm_prmry_reset_out_n_0
    );

end rtl;