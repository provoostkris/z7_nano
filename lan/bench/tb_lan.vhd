------------------------------------------------------------------------------
--  Test Bench for the lan
--  rev. 1.0 : 2024 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
-- just for random functions
use ieee.math_real.all;


-- this bench relies on the https://github.com/provoostkris/netwiz
library nw_util;
context nw_util.nw_util_context;
library nw_ethernet;
use     nw_ethernet.nw_ethernet_pkg.all;

entity tb_lan is
	generic(
    g_speed  :  in  natural   range 100 to 1000
  );
	port(
		y        :  out std_logic
	);
end entity tb_lan;

architecture rtl of tb_lan is

  constant c_ena_tst_1 : boolean := false;
  constant c_ena_tst_2 : boolean := false;
  constant c_ena_tst_3 : boolean := false;
  constant c_ena_tst_4 : boolean := true;

  constant c_rx_mdl_size      : natural   := 80 ;


  -- ethernet packet from https://github.com/jwbensley/Ethernet-CRC32
  constant C_ETH_PKT : t_slv_arr(0 to 101)(7 downto 0) := (x"08", x"00", x"27", x"27", x"1a", x"d5", x"52", x"54",
                                                           x"00", x"12", x"35", x"02", x"08", x"00", x"45", x"00",
                                                           x"00", x"54", x"1e", x"49", x"40", x"00", x"40", x"01",
                                                           x"04", x"50", x"0a", x"00", x"02", x"02", x"0a", x"00",
                                                           x"02", x"0f", x"00", x"00", x"59", x"d6", x"0f", x"af",
                                                           x"00", x"01", x"fd", x"b5", x"f5", x"5a", x"00", x"00",
                                                           x"00", x"00", x"e1", x"95", x"03", x"00", x"00", x"00",
                                                           x"00", x"00", x"10", x"11", x"12", x"13", x"14", x"15",
                                                           x"16", x"17", x"18", x"19", x"1a", x"1b", x"1c", x"1d",
                                                           x"1e", x"1f", x"20", x"21", x"22", x"23", x"24", x"25",
                                                           x"26", x"27", x"28", x"29", x"2a", x"2b", x"2c", x"2d",
                                                           x"2e", x"2f", x"30", x"31", x"32", x"33", x"34", x"35",
                                                           x"36", x"37", x"e6", x"4c", x"b4", x"86");

  constant c_clk_per     : time      := 20 ns ;
  constant c_t_pd        : time      :=  2 ns ;  -- propagation delay added by the PHY

  constant c_tx_ena      : std_logic := '1';
  constant c_tx_err      : std_logic := '0';
  constant c_ipg_len     : natural   := 12 ;

  signal rst_n        : std_ulogic :='0';
  signal clk          : std_ulogic :='0';

--! dut signals
  signal pll_lock          : std_logic;
  signal rgmii_rxc         : std_logic;
  signal rgmii_rx_ctl      : std_logic;
  signal rgmii_rd          : std_logic_vector(3 downto 0);
  signal rgmii_txc         : std_logic;
  signal rgmii_tx_ctl      : std_logic;
  signal rgmii_td          : std_logic_vector(3 downto 0);
  signal phy_rst_n         : std_logic;

--! bench signals
  signal eth_pkt            : t_slv_arr(0 to 1500)(7 downto 0); -- byte array
  type t_mode is            ( loopback,   -- put TX and RX in loop
                              tx_model    -- connect the RX with a TX model
                            );
  signal test_mode          : t_mode;
  signal mdl_rgmii_rx_ctl   : std_logic;
  signal mdl_rgmii_rd       : std_logic_vector(3 downto 0);

  signal tx_header          : t_ethernet_header;               -- header record
  signal tx_payload         : t_slv_arr(0 to C_ETH_PKT'high)(7 downto 0); -- packet payload
  signal tx_pay_len         : integer;
  signal tx_ena             : std_logic := '0';

--! procedures
procedure proc_wait_clk  (
  signal    clk    : in std_logic ;
  constant  cycles : in natural
  ) is
begin
   for i in 0 to cycles-1 loop
    wait until rising_edge(clk);
   end loop;
end procedure;

procedure proc_wait_clk_edge  (
  signal    clk    : in std_logic ;
  constant  edge   : in std_logic
  ) is
begin
    wait until clk'event and clk = edge;
end procedure;

begin

--! standard signals
	clk            <= not clk     after c_clk_per/2   ;

--! dut
dut: entity work.lan(rtl)
  generic map (
    g_sim             => true,
    g_speed           => g_speed
  )
  port map (
    clk               => clk,
    reset_n           => rst_n,

    pll_lock          => pll_lock,
    led               => open,

    rgmii_rxc         => rgmii_rxc    ,
    rgmii_rx_ctl      => rgmii_rx_ctl ,
    rgmii_rd          => rgmii_rd     ,
    rgmii_txc         => rgmii_txc    ,
    rgmii_tx_ctl      => rgmii_tx_ctl ,
    rgmii_td          => rgmii_td     ,
    phy_rst_n         => phy_rst_n    ,

    DDR_addr          => open ,
    DDR_ba            => open ,
    DDR_cas_n         => open ,
    DDR_ck_n          => open ,
    DDR_ck_p          => open ,
    DDR_cke           => open ,
    DDR_cs_n          => open ,
    DDR_dm            => open ,
    DDR_dq            => open ,
    DDR_dqs_n         => open ,
    DDR_dqs_p         => open ,
    DDR_odt           => open ,
    DDR_ras_n         => open ,
    DDR_reset_n       => open ,
    DDR_we_n          => open ,
    FIXED_IO_ddr_vrn  => open ,
    FIXED_IO_ddr_vrp  => open ,
    FIXED_IO_mio      => open ,
    FIXED_IO_ps_clk   => open ,
    FIXED_IO_ps_porb  => open ,
    FIXED_IO_ps_srstb => open
  );


--! models
rgmii_rx_model: entity work.rgmii_rx_model(sim)
  generic map (
    g_speed           => g_speed,
    g_size            => c_rx_mdl_size
  )
  port map (
    rst_n             => rst_n,

    rgmii_rxc         => rgmii_txc    ,
    rgmii_rx_ctl      => rgmii_tx_ctl ,
    rgmii_rd          => rgmii_td
  );

rgmii_tx_model: entity work.rgmii_tx_model(sim)
  generic map (
    g_speed           => g_speed,
    g_size            => C_ETH_PKT'high
  )
  port map (
    rst_n             => rst_n,

    header            => tx_header,
    payload           => tx_payload,
    pay_len           => tx_pay_len,
    tx_ena            => tx_ena,

    rgmii_txc         => rgmii_txc    ,
    rgmii_tx_ctl      => mdl_rgmii_rx_ctl ,
    rgmii_td          => mdl_rgmii_rd
  );


--! test modes
with test_mode select
  rgmii_rxc     <=  rgmii_txc after c_t_pd when loopback,
                    rgmii_txc after c_t_pd when tx_model,
                    '0'                    when others;
with test_mode select
  rgmii_rd      <=  rgmii_td          when loopback,
                    mdl_rgmii_rd      when tx_model,
                    ( others => '0')  when others;
with test_mode select
  rgmii_rx_ctl  <=  rgmii_tx_ctl      when loopback,
                    mdl_rgmii_rx_ctl  when tx_model,
                    '0'               when others;

	--! run test bench
	p_run: process
    --! netwiz packet creation
    variable v_header  : t_ethernet_header;               -- header record
    variable v_payload : t_slv_arr(0 to 101)(7 downto 0); -- packet payload
    variable v_len     : natural;                         -- packet total length
    variable v_eth_pkt : t_slv_arr(0 to 1500)(7 downto 0); -- byte array

	  procedure proc_reset
	    (constant cycles : in natural) is
	  begin
	     rst_n <= '0';
	     for i in 0 to cycles-1 loop
	      wait until rising_edge(clk);
	     end loop;
	     rst_n <= '1';
	  end procedure;

	begin

    if c_ena_tst_1 then
	  report " RUN TST.01 ";
    report " .. simple loop back test , the TX is wired to RX";
    report " .. then the simulation will run for 999 clk cycles";

	    proc_reset(3);

      -- create loop back condition
      test_mode <= loopback ;
      -- wait until the clocks are running and reset is over
      wait until pll_lock = '1';

 	    proc_wait_clk(clk, 999);

	  report " END TST.01 ";
    end if;

    if c_ena_tst_2 then
	  report " RUN TST.02 ";
    report " .. a test packet is crafted and sent to the DUT";
    report " .. the DUT is first resetted and waited for the PLL to lock";

      -- configure test mode
      test_mode <= tx_model ;

      tx_payload                 <= C_ETH_PKT;
      tx_pay_len                 <= C_ETH_PKT'high;
      tx_header                  <= C_DEFAULT_ETH_HEADER;                                -- copy default header
      tx_header.mac_dest         <= f_eth_mac_2_slv_arr("02:AA:BB:CC:DD:EE");            -- change destination MAC

      -- start from reset
	    proc_reset(3);
      -- wait until the clocks are running and reset is over
      wait until pll_lock = '1';
 	    proc_wait_clk(clk, 5);
      tx_ena <= '1';
 	    proc_wait_clk(clk, 5);
      tx_ena <= '0';

 	    proc_wait_clk(clk, 999);
	  report " END TST.02 ";
    end if;

    if c_ena_tst_3 then
	  report " RUN TST.03 ";
    report " .. a dummy packet is crafted x'FE' and sent to the DUT";
    report " .. the DUT is first resetted and waited for the PLL to lock";

      -- configure test mode
      test_mode <= tx_model ;

      for i in C_ETH_PKT'range loop
        tx_payload(i)            <= x"F0";
      end loop;
      tx_pay_len                 <= C_ETH_PKT'high;
      tx_header                  <= C_DEFAULT_ETH_HEADER;                                -- copy default header
      tx_header.mac_dest         <= f_eth_mac_2_slv_arr("02:AA:BB:CC:DD:EE");            -- change destination MAC

      -- start from reset
	    proc_reset(3);
      -- wait until the clocks are running and reset is over
      wait until pll_lock = '1';
 	    proc_wait_clk(clk, 5);
      tx_ena <= '1';

 	    proc_wait_clk(clk, 999);
	  report " END TST.03 ";
    end if;
    
    if c_ena_tst_4 then
	  report " RUN TST.04 ";
    report " .. a dummy packet is crafted with a counter and sent to the DUT";
    report " .. the DUT is first resetted and waited for the PLL to lock";

      -- configure test mode
      test_mode <= tx_model ;

      for i in 0 to 64 loop
        tx_payload(i)            <= std_logic_vector(to_unsigned(i,8));
      end loop;
      tx_pay_len                 <= 65;
      tx_header                  <= C_DEFAULT_ETH_HEADER;                                -- copy default header
      tx_header.mac_dest         <= f_eth_mac_2_slv_arr("99:AA:BB:CC:DD:EE");            -- change destination MAC
      tx_header.mac_src          <= f_eth_mac_2_slv_arr("66:77:88:99:AA:BB");            -- change source MAC

      -- start from reset
	    proc_reset(3);
      -- wait until the clocks are running and reset is over
      wait until pll_lock = '1';
 	    proc_wait_clk(clk, 5);
      tx_ena <= '1';

 	    proc_wait_clk(clk, 999);
	  report " END TST.04 ";
    end if;

	  report " END of test bench" severity failure;

	end process;

end architecture rtl;