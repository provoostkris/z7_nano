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

  signal clk          : std_ulogic :='0';
  signal rst_n        : std_ulogic :='0';
  signal rx_clk       : std_ulogic :='0';

--! dut signals
  signal rgmii_rxc         : std_logic;
  signal rgmii_rx_ctl      : std_logic;
  signal rgmii_rd          : std_logic_vector(3 downto 0);
  signal rgmii_txc         : std_logic;
  signal rgmii_tx_ctl      : std_logic;
  signal rgmii_td          : std_logic_vector(3 downto 0);
  signal phy_rst_n         : std_logic;

--! bench signals
  signal eth_pkt       : t_slv_arr(0 to 1500)(7 downto 0); -- byte array
  signal eth_pkt_byte  : std_logic_vector(7 downto 0);

--! procedures
procedure proc_wait_clk
  (constant cycles : in natural) is
begin
   for i in 0 to cycles-1 loop
    wait until rising_edge(clk);
   end loop;
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

    rgmii_rxc         => rgmii_rxc    ,
    rgmii_rx_ctl      => rgmii_rx_ctl ,
    rgmii_rd          => rgmii_rd     ,
    rgmii_txc         => rgmii_txc    ,
    rgmii_tx_ctl      => rgmii_tx_ctl ,
    rgmii_td          => rgmii_td     ,
    phy_rst_n         => phy_rst_n    ,

    led               => y
  );


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

	  report " RUN TST.01 ";
      --! create a loopback , but not for the clocks
      --! as these are generated on each side of the PHY
      rgmii_rxc    <= rx_clk;
      rgmii_rx_ctl <= rgmii_tx_ctl;
      rgmii_rd     <= rgmii_td;

	    proc_reset(3);
 	    proc_wait_clk(200);

	  report " RUN TST.02 ";

      rgmii_rxc    <= rx_clk;
      rgmii_rx_ctl <= '0';
      rgmii_rd     <= ( others => '0');
      
      v_payload                 := C_ETH_PKT;
      v_header                  := C_DEFAULT_ETH_HEADER;                                -- copy default header
      v_header.mac_dest         := f_eth_mac_2_slv_arr("08:00:27:27:1a:d5");            -- change destination MAC
      v_len                     := f_eth_create_pkt_len(v_header, v_payload);           -- calculate total packet length
      v_eth_pkt(0 to v_len - 1) := f_eth_create_pkt(v_header, v_payload);               -- create the packet
      v_eth_pkt(0 to v_len + 7) := f_concat(C_ETH_PREAMBLE, v_eth_pkt(0 to v_len - 1)); -- add preamble

      eth_pkt       <= v_eth_pkt;
      eth_pkt_byte  <= ( others => '0');

	    proc_reset(3);
 	    for i in 0 to v_len + 7 loop
        proc_wait_clk(1);
        eth_pkt_byte <= eth_pkt(i);
      end loop;





	  report " END of test bench" severity failure;

	end process;

end architecture rtl;