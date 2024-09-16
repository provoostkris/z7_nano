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
	port(
		y        :  out std_logic
	);
end entity tb_lan;

architecture rtl of tb_lan is

  constant c_ena_tst_1 : boolean := true;
  constant c_ena_tst_2 : boolean := true;
  constant c_ena_tst_3 : boolean := true;


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
  constant c_rx_clk_per  : time      :=  8 ns ;
  constant c_t_pd        : time      :=  2 ns ;  -- propagation delay added by the PHY

  constant c_tx_ena      : std_logic := '1';
  constant c_tx_err      : std_logic := '0';
  constant c_ipg_len     : natural   := 12 ;

  signal rst_n        : std_ulogic :='0';
  signal clk          : std_ulogic :='0';
  signal rx_clk       : std_ulogic :='0';

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
	clk            <= not clk     after c_clk_per/2;
	rx_clk         <= not rx_clk  after c_rx_clk_per/2;

--! dut
dut: entity work.lan(rtl)
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

--! test modes
with test_mode select
  rgmii_rxc     <=  rgmii_txc           when loopback,
                    rx_clk after c_t_pd when tx_model,
                    '0'                 when others;
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
    report " .. then the simulation will run for 200 clk cycles";

      mdl_rgmii_rx_ctl <= '0';
      mdl_rgmii_rd     <= ( others => '0');
	    proc_reset(3);

      -- create loop back condition
      test_mode <= loopback ;
      -- wait until the clocks are running and reset is over
      wait until pll_lock = '1';

 	    proc_wait_clk(rx_clk, 250);

	  report " END TST.01 ";
    end if;

    if c_ena_tst_2 then
	  report " RUN TST.02 ";
    report " .. a test packet is crafted and sent to the DUT";
    report " .. the DUT is first resetted and a 250 clk cycles is waited for the PLL to lock";
    report " .. after the packet the IPG sequence is sent to respect the protocol";

      mdl_rgmii_rx_ctl <= '0';
      mdl_rgmii_rd     <= ( others => '0');
	    proc_reset(3);

      -- configure test mode
      test_mode <= tx_model ;
      
      v_payload                 := C_ETH_PKT;
      v_header                  := C_DEFAULT_ETH_HEADER;                                -- copy default header
      v_header.mac_dest         := f_eth_mac_2_slv_arr("02:AA:BB:CC:DD:EE");            -- change destination MAC
      v_len                     := f_eth_create_pkt_len(v_header, v_payload);           -- calculate total packet length
      v_eth_pkt(0 to v_len - 1) := f_eth_create_pkt(v_header, v_payload);               -- create the packet
      v_eth_pkt(0 to v_len + 7) := f_concat(C_ETH_PREAMBLE, v_eth_pkt(0 to v_len - 1)); -- add preamble

      -- create packet for transmission and wait for PLL to lock
	    proc_reset(3);
      eth_pkt       <= v_eth_pkt;
      -- wait until the clocks are running and reset is over
      wait until pll_lock = '1';
 	    proc_wait_clk(rx_clk, 5);

      -- then transmit the packet
 	    for i in 0 to v_len + 7 loop
        -- first nibble
        proc_wait_clk_edge(rx_clk, '1');
        mdl_rgmii_rd     <= eth_pkt(i)(3 downto 0);
        mdl_rgmii_rx_ctl <= c_tx_ena;
        proc_wait_clk_edge(rx_clk, '0');
        mdl_rgmii_rd     <= eth_pkt(i)(7 downto 4);
        mdl_rgmii_rx_ctl <= c_tx_ena xor c_tx_err;
      end loop;
      -- followed by the IPG
 	    for i in 0 to c_ipg_len-1 loop
        -- first nibble
        proc_wait_clk_edge(rx_clk, '1');
        mdl_rgmii_rd     <= ( others => '1');
        mdl_rgmii_rx_ctl <= not c_tx_ena;
        proc_wait_clk_edge(rx_clk, '0');
        mdl_rgmii_rd     <= ( others => '1');
        mdl_rgmii_rx_ctl <= not c_tx_ena xor c_tx_err;
      end loop;

      proc_wait_clk_edge(rx_clk, '1');
      mdl_rgmii_rx_ctl <= '0';
      mdl_rgmii_rd     <= ( others => '0');

 	    proc_wait_clk(rx_clk, 250);
	  report " END TST.02 ";
    end if;

    if c_ena_tst_3 then
	  report " RUN TST.03 ";
    report " .. a dummy packet is crafted x'FE' and sent to the DUT";
    report " .. the DUT is first resetted and a 250 clk cycles is waited for the PLL to lock";
    report " .. after the packet the IPG sequence is sent to respect the protocol";

      mdl_rgmii_rx_ctl <= '0';
      mdl_rgmii_rd     <= ( others => '0');
	    proc_reset(3);

      for i in C_ETH_PKT'range loop
        v_payload(i)            := x"F0";
      end loop;
      v_header                  := C_DEFAULT_ETH_HEADER;                                -- copy default header
      v_header.mac_dest         := f_eth_mac_2_slv_arr("02:AA:BB:CC:DD:EE");            -- change destination MAC
      v_len                     := f_eth_create_pkt_len(v_header, v_payload);           -- calculate total packet length
      v_eth_pkt(0 to v_len - 1) := f_eth_create_pkt(v_header, v_payload);               -- create the packet
      v_eth_pkt(0 to v_len + 7) := f_concat(C_ETH_PREAMBLE, v_eth_pkt(0 to v_len - 1)); -- add preamble

      -- create packet for transmission and wait for PLL to lock
	    proc_reset(3);
      eth_pkt       <= v_eth_pkt;
 	    proc_wait_clk(rx_clk, 250);

      -- then transmit the packet
 	    for i in 0 to v_len + 7 loop
        -- first nibble
        proc_wait_clk_edge(rx_clk, '1');
        mdl_rgmii_rd     <= eth_pkt(i)(3 downto 0);
        mdl_rgmii_rx_ctl <= c_tx_ena;
        proc_wait_clk_edge(rx_clk, '0');
        mdl_rgmii_rd     <= eth_pkt(i)(7 downto 4);
        mdl_rgmii_rx_ctl <= c_tx_ena xor c_tx_err;
      end loop;
      -- followed by the IPG
 	    for i in 0 to c_ipg_len-1 loop
        -- first nibble
        proc_wait_clk_edge(rx_clk, '1');
        mdl_rgmii_rd     <= ( others => '1');
        mdl_rgmii_rx_ctl <= not c_tx_ena;
        proc_wait_clk_edge(rx_clk, '0');
        mdl_rgmii_rd     <= ( others => '1');
        mdl_rgmii_rx_ctl <= not c_tx_ena xor c_tx_err;
      end loop;

      proc_wait_clk_edge(rx_clk, '1');
      mdl_rgmii_rx_ctl <= '0';
      mdl_rgmii_rd     <= ( others => '0');

 	    proc_wait_clk(rx_clk, 250);
    end if;

	  report " END of test bench" severity failure;

	end process;

end architecture rtl;