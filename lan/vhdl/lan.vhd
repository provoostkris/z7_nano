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
    g_speed           : integer range 100 to 1000 := 100;
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
  signal lock_1     : std_logic; --! lock output from the local PLL
  signal lock_2     : std_logic; --! lock output from the local PLL
  signal rst        : std_logic; --! PLL locked inverted
  signal rst_n      : std_logic; --! PLL locked copy
  signal clkfb1     : std_logic; --! required feedback clock for PLL
  signal clkfb2     : std_logic; --! required feedback clock for PLL
  signal clk_125    : std_logic; --! PLL output 125.0 MHz
  signal clk_050    : std_logic; --! PLL output  50.0 MHz
  signal clk_025    : std_logic; --! PLL output  25.0 MHz
  signal clk_012    : std_logic; --! PLL output  12.5 MHz
  signal fclk_clk   : std_logic; --! exported clock from the PS
  signal clk_calib  : std_logic; --! PLL output 200 MHz

  signal clk_sel_pl   : std_logic; --! clock for transfer between PS and PL
  signal clk_sel_tx   : std_logic; --! clock for TX ethernet

--! signals on tx channel
  signal s_tx_dat_tready            : std_logic;
  signal s_tx_dat_tdata             : std_logic_vector(7 downto 0);
  signal s_tx_dat_tkeep             : std_logic_vector(0 downto 0);
  signal s_tx_dat_tlast             : std_logic;
  signal s_tx_dat_tvalid            : std_logic;
  -- unused ports
  signal s_tx_dat_tid               : std_logic_vector(0 downto 0);
  signal s_tx_dat_tdest             : std_logic_vector(0 downto 0);
  signal s_tx_dat_tuser             : std_logic_vector(0 downto 0);
  signal s_tx_status_depth          : std_logic_vector(10 downto 0);
  signal s_tx_status_depth_commit   : std_logic_vector(10 downto 0);
  signal m_tx_status_depth          : std_logic_vector(10 downto 0);
  signal m_tx_status_depth_commit   : std_logic_vector(10 downto 0);

  signal frm_tx_data                : std_logic_vector(7 downto 0);
  signal frm_tx_en                  : std_logic;
  signal frm_tx_err                 : std_logic;

  signal rgmii_tx_clk               : std_logic;

--! signals on rx channel
  signal s_rx_dat_tready  : std_logic;
  signal s_rx_dat_tdata   : std_logic_vector(7 downto 0);
  signal s_rx_dat_tlast   : std_logic;
  signal s_rx_dat_tvalid  : std_logic;
  -- unused ports
  signal s_rx_status_depth          : std_logic_vector(10 downto 0);
  signal s_rx_status_depth_commit   : std_logic_vector(10 downto 0);
  signal m_rx_status_depth          : std_logic_vector(10 downto 0);
  signal m_rx_status_depth_commit   : std_logic_vector(10 downto 0);

  signal frm_rx_len_err : std_logic;
  signal frm_rx_crc_err : std_logic;
  signal frm_rx_pay_len : unsigned(15 downto 0);

  signal frm_rx_rxdv   : std_logic;
  signal frm_rx_rxerr  : std_logic;
  signal frm_rx_ena    : std_logic;
  signal frm_rx_lst    : std_logic;
  signal frm_rx_rxdata : std_logic_vector(7 downto 0);

--! signals for AXIS CH 0
  signal AXI_STR_RXD_0_tdata  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal AXI_STR_RXD_0_tkeep  : STD_LOGIC_VECTOR (  3 downto 0 );
  signal AXI_STR_RXD_0_tlast  : STD_LOGIC;
  signal AXI_STR_RXD_0_tready : STD_LOGIC;
  signal AXI_STR_RXD_0_tvalid : STD_LOGIC;

  signal AXI_STR_RXD_DBG_tdata  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal AXI_STR_RXD_DBG_tkeep  : STD_LOGIC_VECTOR (  3 downto 0 );
  signal AXI_STR_RXD_DBG_tlast  : STD_LOGIC;
  signal AXI_STR_RXD_DBG_tready : STD_LOGIC;
  signal AXI_STR_RXD_DBG_tvalid : STD_LOGIC;
  --unused ports
  signal AXI_STR_RXD_DBG_tid    : STD_LOGIC_VECTOR (  0 downto 0 );
  signal AXI_STR_RXD_DBG_tdest  : STD_LOGIC_VECTOR (  0 downto 0 );
  signal AXI_STR_RXD_DBG_tuser  : STD_LOGIC_VECTOR (  0 downto 0 );

  signal AXI_STR_RXD_SEL_tdata  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal AXI_STR_RXD_SEL_tkeep  : STD_LOGIC_VECTOR (  3 downto 0 );
  signal AXI_STR_RXD_SEL_tlast  : STD_LOGIC;
  signal AXI_STR_RXD_SEL_tready : STD_LOGIC;
  signal AXI_STR_RXD_SEL_tvalid : STD_LOGIC;

  signal AXI_STR_TXD_0_tdata    : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal AXI_STR_TXD_0_tkeep    : STD_LOGIC_VECTOR (  3 downto 0 );
  signal AXI_STR_TXD_0_tlast    : STD_LOGIC;
  signal AXI_STR_TXD_0_tready   : STD_LOGIC;
  signal AXI_STR_TXD_0_tvalid   : STD_LOGIC;

  signal AXI_STR_TXD_DBG_tdata  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal AXI_STR_TXD_DBG_tkeep  : STD_LOGIC_VECTOR (  3 downto 0 );
  signal AXI_STR_TXD_DBG_tlast  : STD_LOGIC;
  signal AXI_STR_TXD_DBG_tready : STD_LOGIC;
  signal AXI_STR_TXD_DBG_tvalid : STD_LOGIC;

  signal AXI_STR_TXD_SEL_tdata  : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal AXI_STR_TXD_SEL_tkeep  : STD_LOGIC_VECTOR (  3 downto 0 );
  signal AXI_STR_TXD_SEL_tlast  : STD_LOGIC;
  signal AXI_STR_TXD_SEL_tready : STD_LOGIC;
  signal AXI_STR_TXD_SEL_tvalid : STD_LOGIC;

  -- APB signals
  signal APB_M1_0_paddr           : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M1_0_penable         : STD_LOGIC;
  signal APB_M1_0_prdata          : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M1_0_pready          : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M1_0_psel            : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M1_0_pslverr         : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M1_0_pwdata          : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M1_0_pwrite          : STD_LOGIC;
  signal APB_M2_0_paddr           : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M2_0_penable         : STD_LOGIC;
  signal APB_M2_0_prdata          : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M2_0_pready          : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M2_0_psel            : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M2_0_pslverr         : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M2_0_pwdata          : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M2_0_pwrite          : STD_LOGIC;
  signal APB_M3_0_paddr           : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M3_0_penable         : STD_LOGIC;
  signal APB_M3_0_prdata          : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M3_0_pready          : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M3_0_psel            : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M3_0_pslverr         : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M3_0_pwdata          : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M3_0_pwrite          : STD_LOGIC;
  signal APB_M4_0_paddr           : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M4_0_penable         : STD_LOGIC;
  signal APB_M4_0_prdata          : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M4_0_pready          : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M4_0_psel            : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M4_0_pslverr         : STD_LOGIC_VECTOR ( 0 to 0 );
  signal APB_M4_0_pwdata          : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal APB_M4_0_pwrite          : STD_LOGIC;

--! spare signals on block design
  signal interrupt_0              :   STD_LOGIC;
  signal mm2s_prmry_reset_out_n_0 :   STD_LOGIC;
  signal s2mm_prmry_reset_out_n_0 :   STD_LOGIC;

  attribute MARK_DEBUG : string;

  -- attribute MARK_DEBUG of  AXI_STR_TXD_SEL_tdata  : signal is "TRUE";
  -- attribute MARK_DEBUG of  AXI_STR_TXD_SEL_tlast  : signal is "TRUE";
  -- attribute MARK_DEBUG of  AXI_STR_TXD_SEL_tready : signal is "TRUE";
  -- attribute MARK_DEBUG of  AXI_STR_TXD_SEL_tvalid : signal is "TRUE";

  attribute MARK_DEBUG of  AXI_STR_RXD_SEL_tdata  : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_RXD_SEL_tlast  : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_RXD_SEL_tready : signal is "TRUE";
  attribute MARK_DEBUG of  AXI_STR_RXD_SEL_tvalid : signal is "TRUE";

  attribute MARK_DEBUG of  frm_rx_rxdv   : signal is "TRUE";
  attribute MARK_DEBUG of  frm_rx_rxerr  : signal is "TRUE";
  attribute MARK_DEBUG of  frm_rx_ena    : signal is "TRUE";
  attribute MARK_DEBUG of  frm_rx_lst    : signal is "TRUE";
  attribute MARK_DEBUG of  frm_rx_rxdata : signal is "TRUE";

  attribute MARK_DEBUG of  rgmii_rd      : signal is "TRUE";
  attribute MARK_DEBUG of  rgmii_rx_ctl  : signal is "TRUE";

begin

  phy_rst_n <= '1';
  reset    <= not reset_n;
  rst      <= not lock_1;
  rst_n    <=     lock_1;
  pll_lock <=     lock_1;

  gen_syn: if g_sim = false generate
    clk_sel_pl              <= fclk_clk;

    AXI_STR_TXD_0_tready    <= AXI_STR_TXD_SEL_tready;
    AXI_STR_TXD_SEL_tdata   <= AXI_STR_TXD_0_tdata ;
    AXI_STR_TXD_SEL_tkeep   <= AXI_STR_TXD_0_tkeep ;
    AXI_STR_TXD_SEL_tlast   <= AXI_STR_TXD_0_tlast ;
    AXI_STR_TXD_SEL_tvalid  <= AXI_STR_TXD_0_tvalid;

    AXI_STR_RXD_SEL_tready  <= AXI_STR_RXD_0_tready;
    AXI_STR_RXD_0_tdata     <= AXI_STR_RXD_SEL_tdata ;
    AXI_STR_RXD_0_tkeep     <= AXI_STR_RXD_SEL_tkeep ;
    AXI_STR_RXD_0_tlast     <= AXI_STR_RXD_SEL_tlast ;
    AXI_STR_RXD_0_tvalid    <= AXI_STR_RXD_SEL_tvalid;
  end generate;

  gen_sim: if g_sim = true generate
    clk_sel_pl              <= clk_050;

    AXI_STR_TXD_DBG_tready  <= AXI_STR_TXD_SEL_tready;
    AXI_STR_TXD_SEL_tdata   <= AXI_STR_TXD_DBG_tdata ;
    AXI_STR_TXD_SEL_tkeep   <= AXI_STR_TXD_DBG_tkeep ;
    AXI_STR_TXD_SEL_tlast   <= AXI_STR_TXD_DBG_tlast ;
    AXI_STR_TXD_SEL_tvalid  <= AXI_STR_TXD_DBG_tvalid;

    AXI_STR_RXD_SEL_tready  <= AXI_STR_RXD_DBG_tready;
    AXI_STR_RXD_DBG_tdata   <= AXI_STR_RXD_SEL_tdata ;
    AXI_STR_RXD_DBG_tkeep   <= AXI_STR_RXD_SEL_tkeep ;
    AXI_STR_RXD_DBG_tlast   <= AXI_STR_RXD_SEL_tlast ;
    AXI_STR_RXD_DBG_tvalid  <= AXI_STR_RXD_SEL_tvalid;
  end generate;

  gen_slow_tx: if g_speed = 100 generate
    clk_sel_tx              <= clk_012;
  end generate;

  gen_fast_tx: if g_speed = 1000 generate
    clk_sel_tx              <= clk_125;
  end generate;

--! indicate the board is running
  i_pwm: entity work.pwm
  port    map (clk_sel_tx, rst_n,led);


  --! user logic with ROM
  i_rom_tx : entity work.rom_tx
    port map (
      clk           => clk_sel_pl,
      rst_n         => rst_n,
      m_tready  => AXI_STR_TXD_DBG_tready,
      m_tdata   => AXI_STR_TXD_DBG_tdata ,
      m_tlast   => AXI_STR_TXD_DBG_tlast ,
      m_tvalid  => AXI_STR_TXD_DBG_tvalid
    );

    -- cheat for now
    AXI_STR_TXD_DBG_tkeep <= ( others => '0');

  --! change the stream data width
  i_axis_async_fifo_adapter_tx : entity work.axis_async_fifo_adapter
    generic map (
      DEPTH           => 2**10,
      S_DATA_WIDTH    => 32,
      M_DATA_WIDTH    => 8,
      ID_WIDTH        => 1,
      DEST_WIDTH      => 1,
      USER_ENABLE     => 0
      )
    port map (
      -- AXI stream input
      s_clk                   => clk_sel_pl,
      s_rst                   => rst,
      s_axis_tready           => AXI_STR_TXD_SEL_tready,
      s_axis_tdata            => AXI_STR_TXD_SEL_tdata,
      s_axis_tvalid           => AXI_STR_TXD_SEL_tvalid,
      s_axis_tlast            => AXI_STR_TXD_SEL_tlast,
      s_axis_tkeep            => AXI_STR_TXD_SEL_tkeep,
      s_axis_tid              => "1",
      s_axis_tdest            => "1",
      s_axis_tuser            => "1",
      -- AXI stream output
      m_clk                   => clk_sel_tx,
      m_rst                   => rst,
      m_axis_tready           => s_tx_dat_tready,
      m_axis_tdata            => s_tx_dat_tdata,
      m_axis_tkeep            => s_tx_dat_tkeep,
      m_axis_tvalid           => s_tx_dat_tvalid,
      m_axis_tlast            => s_tx_dat_tlast,
      m_axis_tid              => s_tx_dat_tid,
      m_axis_tdest            => s_tx_dat_tdest,
      m_axis_tuser            => s_tx_dat_tuser,
      -- pause
      s_pause_req             => '0',
      s_pause_ack             => open,
      m_pause_req             => '0',
      m_pause_ack             => open,
      -- status
      s_status_depth          => s_tx_status_depth,
      s_status_depth_commit   => s_tx_status_depth_commit,
      s_status_overflow       => open,
      s_status_bad_frame      => open,
      s_status_good_frame     => open,
      m_status_depth          => m_tx_status_depth,
      m_status_depth_commit   => m_tx_status_depth_commit,
      m_status_overflow       => open,
      m_status_bad_frame      => open,
      m_status_good_frame     => open
    );

  --! from fifo stream to ethernet frame
  i_eth_frm_tx : entity work.eth_frm_tx
    port map (
      clk          => clk_sel_tx,
      rst_n        => rst_n,

      s_tready     => s_tx_dat_tready,
      s_tdata      => s_tx_dat_tdata,
      s_tlast      => s_tx_dat_tlast,
      s_tvalid     => s_tx_dat_tvalid,

      txdata       => frm_tx_data,
      txen         => frm_tx_en,
      txerr        => frm_tx_err
    );

  --! RGMII TX PHY : normal to reduced interface adapter
  i_rgmii_tx_ddr: entity work.rgmii_tx_ddr
    port map (
      rst          => rst,
      clk          => clk_sel_tx,

      ref_clk      => clk_calib,

      gmii_td      => frm_tx_data,
      gmii_tx_en   => frm_tx_en,
      gmii_tx_err  => frm_tx_err,

      rgmii_txc    => rgmii_tx_clk,
      rgmii_tx_ctl => rgmii_tx_ctl,
      rgmii_td     => rgmii_td
    );

    -- for 100 Mbps use the 25 MHz clock
    -- use the 125 MHz clock for 1000 Mbps
    rgmii_txc <= clk_025 when g_speed = 100 else rgmii_tx_clk;

  --! RGMII RX PHY : reduced to normal interface adapter
  gen_slow_rx: if g_speed = 100 generate
  i_rgmii_rx_sdr: entity work.rgmii_rx_sdr
    port map(
      rst         => rst,

      rgmii_rxc   => rgmii_rxc,
      rgmii_rx_ctl=> rgmii_rx_ctl,
      rgmii_rd    => rgmii_rd    ,

      gmii_rx_dv  => frm_rx_rxdv   ,
      gmii_rx_err => frm_rx_rxerr  ,
      gmii_rx_ena => frm_rx_ena    ,
      gmii_rx_lst => frm_rx_lst    ,
      gmii_rd     => frm_rx_rxdata
    );
   end generate gen_slow_rx;

  gen_fast_rx: if g_speed = 1000 generate
  i_rgmii_rx_ddr: entity work.rgmii_rx_ddr
    port map(
      rst         => rst,

      rgmii_rxc   => rgmii_rxc,
      rgmii_rx_ctl=> rgmii_rx_ctl,
      rgmii_rd    => rgmii_rd    ,

      gmii_rx_dv  => frm_rx_rxdv   ,
      gmii_rx_err => frm_rx_rxerr  ,
      gmii_rd     => frm_rx_rxdata
    );
    frm_rx_ena <= '1';
   end generate gen_fast_rx;

  --! ethernet frame reciever : check ethernet header
  i_eth_frm_rx : entity work.eth_frm_rx
    port map (
      iclk               => rgmii_rxc,
      irst_n             => rst_n,

      irx_lst            => frm_rx_lst,
      irx_ena            => frm_rx_ena,
      irxdata            => frm_rx_rxdata,
      irxdv              => frm_rx_rxdv,
      irxer              => frm_rx_rxerr,

      orxerr             => open,
      olenerr            => frm_rx_len_err,
      ochecksumerr       => frm_rx_crc_err,
      opayloadlen        => frm_rx_pay_len,

      my_dest_mac        => my_mac,
      mac_match          => open,

      osof               => open,
      oeof               => s_rx_dat_tlast,
      orxdata            => s_rx_dat_tdata,
      orxdv              => s_rx_dat_tvalid
    );

  --! convert from byte to word
  i_axis_width_converter_rx : entity work.axis_async_fifo_adapter
    generic map (
      DEPTH           => 2**10,
      S_DATA_WIDTH    => 8,
      M_DATA_WIDTH    => 32,
      ID_WIDTH        => 1,
      DEST_WIDTH      => 1,
      USER_ENABLE     => 0
      )
    port map (
      -- AXI stream input
      s_clk                   => rgmii_rxc,
      s_rst                   => rst,
      s_axis_tready           => s_rx_dat_tready,
      s_axis_tdata            => s_rx_dat_tdata,
      s_axis_tvalid           => s_rx_dat_tvalid,
      s_axis_tlast            => s_rx_dat_tlast,
      s_axis_tkeep            => "1",
      s_axis_tid              => "1",
      s_axis_tdest            => "1",
      s_axis_tuser            => "1",
      -- AXI stream output
      m_clk                   => clk_sel_pl,
      m_rst                   => rst,
      m_axis_tready           => AXI_STR_RXD_SEL_tready,
      m_axis_tdata            => AXI_STR_RXD_SEL_tdata,
      m_axis_tkeep            => AXI_STR_RXD_SEL_tkeep,
      m_axis_tvalid           => AXI_STR_RXD_SEL_tvalid,
      m_axis_tlast            => AXI_STR_RXD_SEL_tlast,
      m_axis_tid              => AXI_STR_RXD_DBG_tid,
      m_axis_tdest            => AXI_STR_RXD_DBG_tdest,
      m_axis_tuser            => AXI_STR_RXD_DBG_tuser,
      -- pause
      s_pause_req             => '0',
      s_pause_ack             => open,
      m_pause_req             => '0',
      m_pause_ack             => open,
      -- status
      s_status_depth          => s_rx_status_depth,
      s_status_depth_commit   => s_rx_status_depth_commit,
      s_status_overflow       => open,
      s_status_bad_frame      => open,
      s_status_good_frame     => open,
      m_status_depth          => m_rx_status_depth,
      m_status_depth_commit   => m_rx_status_depth_commit,
      m_status_overflow       => open,
      m_status_bad_frame      => open,
      m_status_good_frame     => open
    );

    --! just for debugging always consume data
    AXI_STR_RXD_DBG_tready <= '1';

--! we need a pll to make 125.0 mhz from the 50 mhz
--! that ratio is x2.5 , pll needs a number that is with a granularity off 0.125

   -- mmcme2_base: base mixed mode clock manager
   --              artix-7
   -- xilinx hdl language template, version 2023.1

   mmcme2_base_inst1 : mmcme2_base
   generic map (
      bandwidth => "optimized",  -- jitter programming (optimized, high, low)
      clkfbout_mult_f => 25.0,    -- multiply value for all clkout (2.000-64.000).
      clkfbout_phase => 0.0,     -- phase offset in degrees of clkfb (-360.000-360.000).
      clkin1_period => 20.0,      -- input clock period in ns to ps resolution (i.e. 33.333 is 30 mhz).
      -- clkout0_divide - clkout6_divide: divide amount for each clkout (1-128)
      clkout1_divide => 10,
      clkout2_divide => 25,
      clkout3_divide => 50,
      clkout4_divide => 100,
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
      clkout1 => clk_125,     -- 1-bit output: clkout1
      clkout1b => open,   -- 1-bit output: inverted clkout1
      clkout2 => clk_050,     -- 1-bit output: clkout2
      clkout2b => open,   -- 1-bit output: inverted clkout2
      clkout3 => clk_025,     -- 1-bit output: clkout3
      clkout3b => open,   -- 1-bit output: inverted clkout3
      clkout4 => clk_012,     -- 1-bit output: clkout4
      clkout5 => open,     -- 1-bit output: clkout5
      clkout6 => open,     -- 1-bit output: clkout6
      -- feedback clocks: 1-bit (each) output: clock feedback ports
      clkfbout => clkfb1,   -- 1-bit output: feedback clock
      clkfboutb => open, -- 1-bit output: inverted clkfbout
      -- status ports: 1-bit (each) output: mmcm status ports
      locked => lock_1,       -- 1-bit output: lock
      -- clock inputs: 1-bit (each) input: clock input
      clkin1 => clk,       -- 1-bit input: clock
      -- control ports: 1-bit (each) input: mmcm control ports
      pwrdwn => '0',       -- 1-bit input: power-down
      rst => reset,             -- 1-bit input: reset
      -- feedback clocks: 1-bit (each) input: clock feedback ports
      clkfbin => clkfb1      -- 1-bit input: feedback clock
   );



--! we need a pll to make 200.0 mhz from the 50 mhz
--! that ratio is x4.0 , pll needs a number that is with a granularity off 0.125

   -- mmcme2_base: base mixed mode clock manager
   --              artix-7
   -- xilinx hdl language template, version 2023.1

   mmcme2_base_inst2 : mmcme2_base
   generic map (
      bandwidth => "optimized",  -- jitter programming (optimized, high, low)
      clkfbout_mult_f => 20.0,    -- multiply value for all clkout (2.000-64.000).
      clkfbout_phase => 0.0,     -- phase offset in degrees of clkfb (-360.000-360.000).
      clkin1_period => 20.0,      -- input clock period in ns to ps resolution (i.e. 33.333 is 30 mhz).
      -- clkout0_divide - clkout6_divide: divide amount for each clkout (1-128)
      clkout1_divide => 5,
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
      clkout1 => clk_calib,     -- 1-bit output: clkout1
      clkout1b => open,   -- 1-bit output: inverted clkout1
      clkout2 => open,     -- 1-bit output: clkout2
      clkout2b => open,   -- 1-bit output: inverted clkout2
      clkout3 => open,     -- 1-bit output: clkout3
      clkout3b => open,   -- 1-bit output: inverted clkout3
      clkout4 => open,     -- 1-bit output: clkout4
      clkout5 => open,     -- 1-bit output: clkout5
      clkout6 => open,     -- 1-bit output: clkout6
      -- feedback clocks: 1-bit (each) output: clock feedback ports
      clkfbout => clkfb2,   -- 1-bit output: feedback clock
      clkfboutb => open, -- 1-bit output: inverted clkfbout
      -- status ports: 1-bit (each) output: mmcm status ports
      locked => lock_2,       -- 1-bit output: lock
      -- clock inputs: 1-bit (each) input: clock input
      clkin1 => clk,       -- 1-bit input: clock
      -- control ports: 1-bit (each) input: mmcm control ports
      pwrdwn => '0',       -- 1-bit input: power-down
      rst => reset,             -- 1-bit input: reset
      -- feedback clocks: 1-bit (each) input: clock feedback ports
      clkfbin => clkfb2      -- 1-bit input: feedback clock
   );


i_apb3_slave_1 : entity work.apb3_slave
  port map (
    PCLK    => clk_sel_pl,
    PRESETn => rst_n,
    PSEL    => APB_M1_0_psel(0),
    PENABLE => APB_M1_0_penable,
    PWRITE  => APB_M1_0_pwrite,
    PADDR   => APB_M1_0_paddr,
    PWDATA  => APB_M1_0_pwdata,
    PRDATA  => APB_M1_0_prdata,
    PREADY  => APB_M1_0_pready(0),
    PSLVERR => APB_M1_0_pslverr(0)
  );

i_apb3_slave_2 : entity work.apb3_slave
  port map (
    PCLK    => clk_sel_pl,
    PRESETn => rst_n,
    PSEL    => APB_M2_0_psel(0),
    PENABLE => APB_M2_0_penable,
    PWRITE  => APB_M2_0_pwrite,
    PADDR   => APB_M2_0_paddr,
    PWDATA  => APB_M2_0_pwdata,
    PRDATA  => APB_M2_0_prdata,
    PREADY  => APB_M2_0_pready(0),
    PSLVERR => APB_M2_0_pslverr(0)
  );

i_apb3_slave_3 : entity work.apb3_slave
  port map (
    PCLK    => clk_sel_pl,
    PRESETn => rst_n,
    PSEL    => APB_M3_0_psel(0),
    PENABLE => APB_M3_0_penable,
    PWRITE  => APB_M3_0_pwrite,
    PADDR   => APB_M3_0_paddr,
    PWDATA  => APB_M3_0_pwdata,
    PRDATA  => APB_M3_0_prdata,
    PREADY  => APB_M3_0_pready(0),
    PSLVERR => APB_M3_0_pslverr(0)
  );

i_apb3_slave_4 : entity work.apb3_slave
  port map (
    PCLK    => clk_sel_pl,
    PRESETn => rst_n,
    PSEL    => APB_M4_0_psel(0),
    PENABLE => APB_M4_0_penable,
    PWRITE  => APB_M4_0_pwrite,
    PADDR   => APB_M4_0_paddr,
    PWDATA  => APB_M4_0_pwdata,
    PRDATA  => APB_M4_0_prdata,
    PREADY  => APB_M4_0_pready(0),
    PSLVERR => APB_M4_0_pslverr(0)
  );

--! add the block design containing the processor
  bd_base_i: entity work.bd_base
    port map (

      FCLK_CLK0_0 => fclk_clk,

      AXI_STR_RXD_0_tdata(31 downto 0) => AXI_STR_RXD_0_tdata(31 downto 0),
      AXI_STR_RXD_0_tkeep => AXI_STR_RXD_0_tkeep,
      AXI_STR_RXD_0_tlast => AXI_STR_RXD_0_tlast,
      AXI_STR_RXD_0_tready => AXI_STR_RXD_0_tready,
      AXI_STR_RXD_0_tvalid => AXI_STR_RXD_0_tvalid,

      AXI_STR_TXD_0_tdata(31 downto 0) => AXI_STR_TXD_0_tdata(31 downto 0),
      AXI_STR_TXD_0_tkeep => AXI_STR_TXD_0_tkeep,
      AXI_STR_TXD_0_tlast => AXI_STR_TXD_0_tlast,
      AXI_STR_TXD_0_tready => AXI_STR_TXD_0_tready,
      AXI_STR_TXD_0_tvalid => AXI_STR_TXD_0_tvalid,

      APB_M1_0_paddr           => APB_M1_0_paddr,
      APB_M1_0_penable         => APB_M1_0_penable,
      APB_M1_0_prdata          => APB_M1_0_prdata,
      APB_M1_0_pready          => APB_M1_0_pready,
      APB_M1_0_psel            => APB_M1_0_psel,
      APB_M1_0_pslverr         => APB_M1_0_pslverr,
      APB_M1_0_pwdata          => APB_M1_0_pwdata,
      APB_M1_0_pwrite          => APB_M1_0_pwrite,
      APB_M2_0_paddr           => APB_M2_0_paddr,
      APB_M2_0_penable         => APB_M2_0_penable,
      APB_M2_0_prdata          => APB_M2_0_prdata,
      APB_M2_0_pready          => APB_M2_0_pready,
      APB_M2_0_psel            => APB_M2_0_psel,
      APB_M2_0_pslverr         => APB_M2_0_pslverr,
      APB_M2_0_pwdata          => APB_M2_0_pwdata,
      APB_M2_0_pwrite          => APB_M2_0_pwrite,
      APB_M3_0_paddr           => APB_M3_0_paddr,
      APB_M3_0_penable         => APB_M3_0_penable,
      APB_M3_0_prdata          => APB_M3_0_prdata,
      APB_M3_0_pready          => APB_M3_0_pready,
      APB_M3_0_psel            => APB_M3_0_psel,
      APB_M3_0_pslverr         => APB_M3_0_pslverr,
      APB_M3_0_pwdata          => APB_M3_0_pwdata,
      APB_M3_0_pwrite          => APB_M3_0_pwrite,
      APB_M4_0_paddr           => APB_M4_0_paddr,
      APB_M4_0_penable         => APB_M4_0_penable,
      APB_M4_0_prdata          => APB_M4_0_prdata,
      APB_M4_0_pready          => APB_M4_0_pready,
      APB_M4_0_psel            => APB_M4_0_psel,
      APB_M4_0_pslverr         => APB_M4_0_pslverr,
      APB_M4_0_pwdata          => APB_M4_0_pwdata,
      APB_M4_0_pwrite          => APB_M4_0_pwrite,

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